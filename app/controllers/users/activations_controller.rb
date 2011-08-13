class Users::ActivationsController < ApplicationController

  skip_before_filter :require_user
  before_filter :require_no_user

  #
  # Setup basic profile after registering for an echo account with an E-Mail address.
  #
  def basic_profile
    later_call_with_info(root_path, request.url) do |format|
      format.js {
       @user = User.find_by_perishable_token(params[:activation_code], 1.week)
       if @user.nil?
         set_error "users.activation.messages.no_account"
         render_with_error
       elsif @user.active?
         set_error "users.activation.messages.already_active"
         render_with_error
       else
         render :template => 'users/components/users_form',
                :locals => {:partial => 'users/activations/basic_profile'}
       end
       }
    end
  end


  #
  # We arrive here from setup basic profile form or via following the activation link sent by an Email.
  #
  def activate
    @user = User.find_by_perishable_token(params[:activation_code], 1.week)

    begin
      User.transaction do

        via_form = params.has_key?(:user)
        if @user.nil?
          redirect_or_render_with_error(root_path, "users.activation.messages.no_account")
          return
        elsif via_form # Coming from setup basic profile form
          if params[:user].delete(:agreement).nil?
            redirect_or_render_with_error(root_path, "users.activation.messages.no_agreement")
            return
          elsif params[:user][:full_name].try(:strip).blank?
            redirect_or_render_with_error(root_path, "users.activation.messages.no_full_name")
            return
          end
        end
        if @user.active?
          redirect_or_render_with_error(root_path, "users.activation.messages.already_active")
          return
        end


        if @user.email or @user.has_verified_email? params[:user][:email]
          # Given email is a verified email, therefore, no activation is needed
          if @user.activate!(params[:user]) and @user.profile.save # so that the name persists
            UserSession.create(@user, false)
            @user.deliver_activation_confirmation!
            redirect_with_info(my_profile_path, 'users.activation.messages.success')
          else
            set_error 'users.activation.messages.failed'
            redirect_or_render_with_error(root_path, @user)
          end

        else
          # via_form === true, given email is not verified, therefore, send activation email

          # Check if Email exists
          if !params[:user][:email].blank?
            if User.find_by_email(params[:user][:email])
              redirect_or_render_with_error(settings_path, "activerecord.errors.models.user.attributes.email.taken")
              return
            end

            if @user.signup!(params[:user]) and @user.profile.save
              @user.deliver_activate!
              redirect_or_render_with_info(root_path, 'users.users.messages.created') do |page|
                page << "$('#dialogContent').dialog('close');"
              end
            else
              set_error 'users.activation.messages.failed'
              later_call_with_error(request.referer, signup_url, @user)
            end
          else
              set_error 'activerecord.errors.messages.blank', :attribute => I18n.t('application.general.email')
              later_call_with_error(request.referer, signup_url, @user)
          end
        end
      end
    end
  rescue Exception => e
    log_message_error(e, "Error activating user")
  else
    log_message_info("User '#{@user.id}' has been activated sucessfully.")
  end

  def activate_email
    @action = PendingAction.find(params[:token])

    if @action.nil?
      redirect_or_render_with_error(root_path, "users.activation.messages.no_account")
    elsif @action.status
      redirect_or_render_with_error(root_path, "users.activation.messages.already_active")
    else
      @user = @action.pending
      User.transaction do
        if @user.update_attributes(JSON.parse(@action.action))
          @action.update_attribute(:status, true)
          UserSession.create(@user, false)
          @user.deliver_activation_confirmation!
          redirect_with_info(my_profile_path, 'users.activation.messages.email_success')
        else
          set_error 'users.activation.messages.failed'
          redirect_or_render_with_error(root_path, @user)
        end
      end
    end
  end
end
