require 'singleton'

class ActivityTrackingService
  include Singleton

  attr_accessor :period, :charges

  def initialize
  end

  def update(*args)
    send(*args)
  end


  #########
  # Hooks #
  #########

  def supported(echoable, user)
    return if user.nil?
    if !echoable.subscriptions.find_by_subscriber_id(user.id)
      user.subscriptions << Subscription.new(:subscriber => user,
                                             :subscribeable => echoable)
    end
    if echoable.parent_node && !echoable.parent_node.subscriptions.find_by_subscriber_id(user.id)
      user.subscriptions << Subscription.new(:subscriber => user,
                                             :subscribeable => echoable.parent_node)
    end
  end

  def unsupported(echoable, user)
    return if user.nil?
    subscription = echoable.subscriptions.find_by_subscriber_id(user.id)
    echoable.subscriptions.delete(subscription) if subscription
  end

  def created(node)
    published(node) if node.published?
  end

  def published(node)
    created_event(node)
  end

  def incorporated(echoable, user)
  end


  #################
  # Service logic #
  #################

  #
  # Creates an event for the newly created subscribeable object
  #
  def created_event(node)

    event = {
      :operation => 'created',
      :type => node.u_class_name,
      :info_type => node.class.has_embeddable_data? ? node.info_type.code : nil,
      :id => node.target_id,
      :level => node.class.is_top_statement? ? node.parent_node.level + 1 : node.level,
      :top_level => node.top_level,
      :tags => node.filtered_topic_tags,
      :documents => set_titles_hash(node.statement_documents),
      :parent_documents => node.parent_node ? set_titles_hash(node.parent_node.statement_documents) : nil,
      :parent_id => node.parent_id || -1
    }

    Event.create(:event => event,
                 :operation => 'created',
                 :broadcast => node.parent_node.nil? ? true : false,
                 :subscribeable => node.parent_node.nil? ? node : node.parent)
  end

  def set_titles_hash(documents)
    documents.each_with_object({}) do |document, titles_hash|
      titles_hash[document.language_id] = document.title
    end
  end


  #
  # Manages the counter to calculate current charge and schedules the next job with it.
  #
  def enqueue_activity_tracking_job(current_job_id = 0)

    # After restarting the process (on new deployment) the
    # counter is initialized with the current job id.
    job_id = current_job_id + 1

    # Enqueuing the next job
    Delayed::Job.enqueue ActivityTrackingJob.new(job_id, job_id % @charges), 0,
                         Time.now.utc.advance(:seconds => @period/@charges)
  end


  #
  # Actually executes the job, generates activity mails, sends them and schedules the next job.
  #
  def generate_activity_mails(current_job_id, current_charge)

    # Enqueuing the next job
    enqueue_activity_tracking_job(current_job_id)

    # Iterating over users in the current charge
    User.activity_recipients.scoped(:conditions => ["(id % ?) = ?", @charges, current_charge]).map(&:id).each do |recipient_id|
      generate_activity_mail(recipient_id)
    end
  end


  #
  # Assembles and sends an activity mail to the given recipient.
  # Executed async in production environment.
  #
  def generate_activity_mail(recipient_id)
    recipient = User.find(recipient_id)

    # Collecting events
    events = Event.find_tracked_events(recipient)
    last_event = events.first
    events.map!(&:event)

    # Filter only events whose titles languages the recipient speaks
    events.reject!{|e| (e[:documents].keys.map{|id|id.to_i} & user_filtered_languages(recipient)).empty? }

    return if events.blank? #if there are no events to send per email, take the next user

    root_events, events, question_tag_counts = build_events_hash(events)

    # Sending the mail
    send_activity_mail(recipient, root_events, question_tag_counts, events)

    # Adjust last processed event
    recipient.subscriber_data.update_attribute :last_processed_event, last_event
  end

  def build_events_hash(events)

    # Take the question events apart
    root_events = events.select{|e| e[:level] == 0 and e[:top_level]}
    events -= root_events

    # Create a Hash containing the number of occurrences of the new tags in the new questions
    question_tag_counts = root_events.each_with_object({}) do |root, tags_hash|
      root[:tags].each{|tag| tags_hash[tag] = tags_hash.has_key?(tag) ? tags_hash[tag] + 1 : 1 }
    end

    # Turn array of events into an hash
    events = events.each_with_object({}) do |e, hash|
      hash[e[:level]] ||= {}
      hash[e[:level]][e[:parent_id]] ||= {}
      hash[e[:level]][e[:parent_id]][e[:type]] ||= {}
      hash[e[:level]][e[:parent_id]][e[:type]][e[:operation]] ||= []
      hash[e[:level]][e[:parent_id]][e[:type]][e[:operation]] << e
    end

    [root_events, events, question_tag_counts]

  end

  #
  # Sends an activity tracking mail to the given recipient.
  #
  def send_activity_mail(recipient, root_events, question_tag_counts, events)
    puts "Send mail to:" + recipient.email
    ActivityTrackingMailer.deliver_activity_tracking_mail(recipient, root_events, question_tag_counts, events)
  end

  #################
  # Aux Functions #
  #################

  def user_filtered_languages(user)
    spoken_languages = user.sorted_spoken_languages
    spoken_languages << user.default_language.id if spoken_languages.empty? and user.default_language
    spoken_languages
  end


  ###############
  # Async calls #
  ###############

  #handle_asynchronously :generate_activity_mail

end