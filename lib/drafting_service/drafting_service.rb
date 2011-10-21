require 'singleton'

class DraftingService
  include Singleton


  ##############
  # Parameters #
  ##############

  @@min_quorum = 0.5
  @@min_votes  = 2
  @@time_ready  = 24.hours
  @@time_approved  = 24.hours
  @@time_approval_reminder  = 18.hours

  def self.min_quorum=(value)
    @@min_quorum = value
  end

  def self.min_votes=(value)
    @@min_votes = value
  end

  def self.time_ready
    @@time_ready
  end

  def self.time_ready=(value)
    @@time_ready = value
  end

  def self.time_approved=(value)
    @@time_approved = value
  end

  def self.time_approval_reminder=(value)
    @@time_approval_reminder = value
  end

  def update(*args)
    send(*args)
  end


  # Derived time parameters for mailing

  def self.approved_hours
    @@time_approved.to_i / 3600
  end

  def self.approved_hours_left
    (@@time_approved - @@time_approval_reminder).to_i / 3600
  end


  ###############
  # Event hooks #
  ###############

  # Observer to echoable support action
  def supported(echoable, user)
    adjust_states(echoable, echoable.supporter_count.to_i-1)
  end

  # Observer to echoable unsupport action
  def unsupported(echoable, user)
    adjust_states(echoable, echoable.supporter_count.to_i+1)
  end

  # Observer to subscribeable created action
  def created(node)
  end


  # Observer to subscribeable publish action
  def published(node)
  end

  # Observer to incorporable incorporated action
  def incorporated(incorporable, user)
    incorporable.reload
    incorporate(incorporable)
    select_approved(incorporable)
  end


  #################
  # State machine #
  #################

  #
  # Reacts on echo/unecho event. I.e. when it's incorporable updates the sibling states, when draftable,
  # adjust the readiness of the children.
  #
  def adjust_states(echoable, old_supporter_count)
    if echoable.incorporable?
      siblings = echoable.sibling_statements
      update_incorporable_states(siblings, echoable, old_supporter_count)
    elsif echoable.draftable?
      children = echoable.child_statements.select(&:incorporable?)
      children.each do |child|
        adjust_readiness(child, false, true)
      end
    end
  end

  #
  # Calculate which incorporable's positions (ordered per supported_count) have changed, and update their states.
  #
  def update_incorporable_states(incorporables, changed_incorporable, old_supporter_count)
    # Get array order with id and supporter count
    old_order = incorporables.map{|inc| [inc.id, inc.supporter_count.to_i, inc.created_at.to_i]}
    
    # Set the old supporter count on the changed incorporable
    old_order[incorporables.index(changed_incorporable)][1] = old_supporter_count

    # Sort the array, thus getting the ordered array before the support/unsupport action
    old_order.sort! do |a, b|
      position_diff = b[1] <=> a[1] # Desc by position
      position_diff != 0 ? position_diff : a[2] <=> b[2] # Asc by created_at
    end
    
    old_order.map!{|i| i[0]}
    incorporables.each_with_index do |inc, new_position|
      old_position = old_order.index(inc.id)
      if new_position > old_position or inc == changed_incorporable
        adjust_readiness(inc, new_position > old_position, inc == changed_incorporable)
      end
    end
  end

  #
  # According to the given parameters, will either readify or track the incorporable.
  #
  def adjust_readiness(incorporable, position_decreased, changed_criteria)
    readiness = test_readiness(incorporable)
    if ((incorporable.tracked? and changed_criteria) or (!incorporable.tracked? and position_decreased)) and
        readiness
        readify(incorporable)
    elsif !incorporable.tracked? and changed_criteria and !readiness
      track(incorporable)
    end
  end

  #
  # Test if incorporable fulfills all conditions to become ready.
  #
  def test_readiness(incorporable)
    incorporable.supporter_count >= @@min_votes and incorporable.quorum > @@min_quorum
  end

  #
  # Set incorporable state to tracked.
  #
  def track(incorporable)
    set_track(incorporable)
  end

  #
  # Set incorporable state to ready.
  #
  def readify(incorporable)
    set_readify(incorporable)
    incorporable.reload
    Delayed::Job.enqueue TestForStagedJob.new(incorporable.id,incorporable.state_since), 1,
                         Time.now.advance(:seconds => @@time_ready).utc
  end

  #
  # Set incorporable state to staged.
  #
  def stage(incorporable)
    set_stage(incorporable)
    incorporable.reload
    select_approved(incorporable)
  end

  #
  # Select the suitable sibling from the incorporable to become approved.
  #
  def select_approved(incorporable)
    incorporable.reload
    if incorporable.parent_node.approved_children.empty?
      siblings = incorporable.sibling_statements(:language_ids => [incorporable.drafting_language.id]).select(&:staged?)
      approve(siblings.first) if !siblings.empty?
    end
  end

  #
  # Set incorporable state to approved.
  #
  def approve(incorporable)
    set_approve(incorporable)
    incorporable.reload
    send_approval_mails(incorporable)
    Delayed::Job.enqueue TestForPassedJob.new(incorporable.id), 1,
                         Time.now.advance(:seconds => @@time_approved).utc
  end

  #
  # Sends the reminder mails to the appropriate recipients.
  #
  def remind(incorporable)
    # First round
    if incorporable.times_passed == 0
      send_approval_reminder_mail(incorporable)

    # Second round
    elsif incorporable.times_passed == 1
      send_supporters_approval_reminder_mail(incorporable)
    end
  end

  #
  # Set incorporable state to incorporated.
  #
  def incorporate(incorporable)
    set_incorporate(incorporable)
    incorporable.reload
    send_incorporation_mails(incorporable)
  end

  #
  # Called if the user(s) passed to incorporate the statement.
  #
  def pass(incorporable)
    begin
      StatementNode.transaction do
        incorporable.times_passed += 1
        incorporable.drafting_info.save
        incorporable.reload

        # First round
        if incorporable.times_passed == 1
          send_passed_mail(incorporable)
          stage(incorporable)

        # Second round
        elsif incorporable.times_passed == 2
          send_supporters_passed_mail(incorporable)
          reset(incorporable)
        end
      end
    rescue StandardError => error
      puts "Error passing IP '#{incorporable.id}':" + error.backtrace
    end
  end


  #
  # Removes all echos and sends the statement back to tracked state.
  #
  def reset(incorporable)
    withdraw_echos(incorporable)
    incorporable.times_passed = 0
    incorporable.drafting_info.save
    incorporable.reload
    set_track(incorporable)
    incorporable.reload
    select_approved(incorporable)
  end


  #################
  # SENDING MAILS #
  #################

  #
  # Sends mails when the statement became approved.
  #
  def send_approval_mails(incorporable)
    incorporable.reload
    mail_data = prepare_mail(incorporable)

    # Send notification that the statement can be incorporated
    ip_recipients = []
    approved_document = incorporable.document_in_drafting_language

    # First round
    if incorporable.times_passed == 0 && approved_document.author.drafting_notification == 1
      ip_recipients << approved_document.author
      email = DraftingMailer.create_approval(mail_data)
      DraftingMailer.deliver(email)

    # Second round
    elsif incorporable.times_passed == 1
      ip_recipients = notified_supporters(incorporable)
      if !ip_recipients.blank?
        email = DraftingMailer.create_supporters_approval(ip_recipients, mail_data)
        DraftingMailer.deliver(email)
      end
    end

    # Send approval notification to the rest of the supporters of the proposal
    p_recipients = notified_supporters(incorporable.parent_node) - ip_recipients
    if !p_recipients.blank?
      email = DraftingMailer.create_approval_notification(p_recipients, mail_data)
      DraftingMailer.deliver(email)
    end

    # Schedule job to send reminder mails
    Delayed::Job.enqueue ApprovalReminderMailJob.new(incorporable.id, incorporable.state_since), 1,
                         Time.now.advance(:seconds => @@time_approval_reminder)
  end

  #
  # Sends the approval reminder mail to the author of the incorporable.
  #
  def send_approval_reminder_mail(incorporable)
    approved_document = incorporable.document_in_drafting_language
    if approved_document.author.drafting_notification == 1
      email = DraftingMailer.create_approval_reminder(prepare_mail(incorporable))
      DraftingMailer.deliver(email)
    end
  end

  #
  # Sends the approval reminder mail to all supporters of the incorporable.
  #
  def send_supporters_approval_reminder_mail(incorporable)
    recipients = notified_supporters(incorporable)
    if !recipients.blank?
      email = DraftingMailer.create_supporters_approval_reminder(recipients, prepare_mail(incorporable))
      DraftingMailer.deliver(email)
    end
  end

  #
  # Sends mail to notify the author that he has passed the opportunity to incorporate his statement.
  #
  def send_passed_mail(incorporable)
    passed_document = incorporable.document_in_drafting_language
    if passed_document.author.drafting_notification == 1
      email = DraftingMailer.create_passed(prepare_mail(incorporable))
      DraftingMailer.deliver(email)
    end
  end

  #
  # Sends mail to notify all supporters of the statement that they have passed the opportunity to incorporate it.
  #
  def send_supporters_passed_mail(incorporable)
    recipients = notified_supporters(incorporable)
    if !recipients.blank?
      email = DraftingMailer.create_supporters_passed(recipients, prepare_mail(incorporable))
      DraftingMailer.deliver(email)
    end
  end

  #
  # Sends mail author that he has passed the opportunity to incorporate his statement.
  #
  def send_incorporation_mails(incorporable)
    mail_data = prepare_mail(incorporable)

    # Thank you mail to the author
    ip_recipient = []
    draftable_document = incorporable.parent_node.document_in_drafting_language
    if draftable_document.author.drafting_notification == 1
      ip_recipient << draftable_document.author
      email = DraftingMailer.create_incorporated(mail_data)
      DraftingMailer.deliver(email)
    end

    # Notification mail to the rest of the supporters of the proposal
    p_recipients = notified_supporters(incorporable.parent_node) - ip_recipient
    if !p_recipients.blank?
      email = DraftingMailer.create_incorporation_notification(p_recipients, mail_data)
      DraftingMailer.deliver(email)
    end
  end

  #
  # Sets the language of the mail and returns a map with data used to create the mail body.
  #
  def prepare_mail(incorporable)

    # Setting the language of the mail - and all its links
    # It can be done this way because all mailings are executed asynchronously by delayed_job, thus
    # they are outside of the scope of user sessions
    I18n.locale = incorporable.drafting_language.code.to_sym

    # Generating the mail data
    {
      :incorporable => incorporable,
      :draftable => incorporable.parent_node,
      :incorporable_document => incorporable.document_in_drafting_language,
      :draftable_document => incorporable.parent_node.document_in_drafting_language,
      :language => incorporable.drafting_language.code
    }
  end


  private

  #
  # Returns those supporters of the echoable who would like to receive drafting notifications.
  #
  def notified_supporters(echoable, check_language_skills = false)
    echoable.reload
    echoable.supporters.select{|supporter|
      supporter.drafting_notification == 1 &&
      (!check_language_skills || supporter.speaks_language?(echoable.original_language, 'intermediate'))
    }
  end

  #
  # Withdraws all echos from the given echoable.
  #
  def withdraw_echos(echoable)
    echoable.user_echos.supported.all.each{|ue|
      ue.supported = false
      ue.save
    }
    echoable.reload
    echoable.echo.update_counter!
    echoable.echo.save
    echoable.save
  end

  #
  # Sets and persists the given state and the state_since timestamp.
  #
  %w(track readify stage approve incorporate).each do |transition|
    define_method "set_#{transition}" do |incorporable|
      incorporable = StatementNode.find(incorporable.id) if incorporable.readonly?
      incorporable.state_since = Time.now.utc
      incorporable.drafting_info.save
      incorporable.send("#{transition}!")
      incorporable.save
    end
  end

  ###############
  # Async calls #
  ###############

  handle_asynchronously :send_incorporation_mails

end