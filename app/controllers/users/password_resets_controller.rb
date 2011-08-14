# A password reset will be used to give Users the possibility to update
# their password. Authentification based on authlogic's perishable_token.
#
class Users::PasswordResetsController < ApplicationController

  skip_before_filter :require_user
  # Use perishable_token on edit or update methods
  before_filter :load_user_using_perishable_token, :only => [:update]

  # Render password reset creation partial
  def new
    render_static_new :template => 'users/password_resets/new' do |format|
      format.js {render :template => 'users/components/users_form',
                        :locals => {:partial => 'users/password_resets/new', :css_class => "basic_profile_box"}}
    end
  end

  # Creates a new password reset process and sends an email to the user.
  def create
    @user = User.find_by_email(params[:email])
    begin
      if @user
        @user.deliver_password_reset_instructions!
        redirect_with_info(base_url, 'users.password_reset.messages.success')
      else
        later_call_with_error(base_url, new_password_reset_path, 'users.password_reset.messages.not_found')
      end
    rescue Exception => e
      log_message_error(e, "Error creating user '#{@user.nil? ? params[:email] : @user.id}' password.")
    else
      log_message_info("User '#{@user.nil? ? params[:email] : @user.id}' password has been created sucessfully.")
    end
  end

  # Render the edit partial
  def edit
    later_call_with_info(base_url, request.url) do |format|
      format.js {
        load_user_using_perishable_token(true)
        render :template => 'users/components/users_form',
               :locals => {:partial => 'users/password_resets/edit', :css_class => "basic_profile_box"}
      }
    end
  end

  def update
    @user.active = true
    begin
      @user.old_password = true # Variable that allows the password validations. TODO: rename it
      if @user.update_attributes(params[:user])
        redirect_with_info(base_url, 'users.password_reset.messages.reset_success')
      else
        set_error @user#'users.password_reset.messages.reset_failed'
        later_call_with_error(base_url, request.referer, @user)
      end
    rescue Exception => e
      log_message_error(e, "Error updating user '#{@user.id}' password.")
    else
      log_message_info("User '#{@user.nil? ? params[:email] : @user.id}' password has been updated sucessfully.")
    end
  end

  # ------------------------------------------------------------------
  # PRIVATE
  #
  private

  def load_user_using_perishable_token(js=false)
    @user = User.find_by_perishable_token(params[:id])
    unless @user
      flash[:notice] = "We're sorry, but we could not locate your account. " +
        "If you are having issues try copying and pasting the URL " +
        "from your email into your browser or restarting the " +
        "reset password process."
        if js
          render :update do |page|
            page.redirect_to base_url
          end
        else
          redirect_to base_url
        end
    end
  end

end
