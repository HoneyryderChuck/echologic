class Users::UsersController < ApplicationController
  include Users::SocialModule

  before_filter :require_no_user, :only => [:new, :create, :create_social, :setup_basic_profile]
  skip_before_filter :require_user, :only => [:index, :new, :create, :create_social, :setup_basic_profile]
  before_filter :fetch_user, :only => [:show, :edit, :update, :destroy]

  access_control do
    allow logged_in, :to => [:show, :index, :update, :destroy_account, :update_email, :update_password,
                             :add_concernments, :delete_concernment, :auto_complete_for_tag_value,
                             :add_social, :remove_social]
    allow :admin
    allow anonymous, :to => [:new, :create, :create_social, :setup_basic_profile]
  end

  # Generate auto completion based on tags in the database
  auto_complete_for :tag, :value, :limit => 20 do |tags|
    @@tag_filter.call %w(* #), tags, 7
  end


  # GET /users
  # GET /users.xml
  def index
    @users = User.all
    respond_to do |format|
      format.html
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    respond_to do |format|
      format.html
      format.js
    end
  end


  # GET /users/new
  # GET /users/new.xml
  def new
    session[:redirect_url] = last_url
    render_signinup :signup
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # modified users_controller.rb
  def create
    redirect_url = session.delete(:redirect_url) || my_profile_path
    @user = User.new
    begin
      if @user.signup!(params[:user])
        @user.deliver_activation_instructions!
        redirect_or_render_with_info(redirect_url, 'users.users.messages.created') do |page|
          page << "$('#dialogContent').dialog('close');"
        end
      else
        later_call_with_error(redirect_url, signup_url, @user)
      end
    rescue Exception => e
      log_message_error(e, "Error creating user")
    else
      log_message_info("User '#{@user.id}' has been created sucessfully.")
    end
  end


  # PUT /users/1
  # PUT /users/1.xml
  def update
    begin
      respond_to do |format|
        if @user.update_attributes(params[:user])
          flash[:notice] = "User was successfully updated."
          format.html { redirect_to(profile_path) }
        else
          format.html { render :action => "edit" }
        end
      end
    rescue Exception => e
      log_message_error(e, "Error updating user #{@user.id}")
    else
      log_message_info("User '#{@user.id}' has been updated sucessfully.")
    end
  end

  def update_email
    User.transaction do
      if current_user.crypted_password.blank?
        redirect_or_render_with_error(settings_path, "users.echo_account.change_email.no_password")
      elsif !current_user.has_password? params[:user].delete(:password)
        redirect_or_render_with_error(settings_path, "activerecord.errors.models.user.attributes.password.invalid")
      elsif params[:user][:email].eql? params[:user][:email_confirmation]

        # Check if Email exists
        if User.find_by_email(params[:user][:email])
          redirect_or_render_with_error(settings_path, "activerecord.errors.models.user.attributes.email.taken")
          return
        end

        # Have it already as verified Mail?
        if current_user.has_verified_email?(params[:user][:email])

          # Change now
          if current_user.update_attributes(params[:user])
            redirect_or_render_with_info(settings_path, "users.echo_account.change_email.success") do |page|
              close_panel(page)
            end
          else
            redirect_or_render_with_error(settings_path, current_user)
          end

        else
          # Validate per Mail and change in a pending action
          pending_action = PendingAction.create(:action => params[:user].to_json, :pending => current_user)
          current_user.deliver_activate_email!(params[:user][:email], pending_action.uuid)
          redirect_or_render_with_info(settings_path, "users.users.messages.activate_email") do |page|
            close_panel(page)
          end
        end
      else
        redirect_or_render_with_error(settings_path, "activerecord.errors.messages.confirmation",
                                      :attribute => I18n.t("application.general.email"))
      end
    end
  end

  def close_panel(page)
    page << "$('#change_email').removeClass('active');"
    page << "$('#echo_account_settings .content').animate(toggleParams,1000, function(){$(this).remove()});"
    page
  end

  def update_password
    old_password = params[:user][:old_password]
    begin
      if current_user.crypted_password.blank? or current_user.has_password?(old_password)
        if current_user.update_attributes(params[:user])
          redirect_or_render_with_info(settings_path, 'users.echo_account.change_password.success') do |page|
            page << "$('#change_password').removeClass('active');"
            page << "$('#echo_account_settings .content').removeClass('active').animate(toggleParams,1000, function(){$(this).remove()});"
          end
        else
          redirect_or_render_with_error(settings_path, current_user)
        end
      else
        redirect_or_render_with_error(settings_path, "users.echo_account.change_password.wrong_password")
      end
    rescue Exception => e
      log_message_error(e, "Error updating user #{current_user.id} password")
    else
      log_message_info("User '#{current_user.id}' password has been updated sucessfully.")
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    begin
      @user.delete_account
      respond_to do |format|
        flash[:notice] = "User account has been removed."
        format.html { redirect_to connect_path }
      end
    rescue Exception => e
      log_message_error(e, "Error deleting account from user '#{@user.id}'.")
    else
      log_message_info("User '#{@user.id}' account has been sucessfully deleted.")
    end
  end

  def destroy_account
    begin
      User.transaction do
        if current_user.crypted_password.blank? or current_user.has_password?(params[:password])
          current_user_session.destroy
          reset_session
          current_user.delete_account
          respond_to do |format|
            set_info "users.echo_account.delete_account.success"
            format.html { flash_info and redirect_to root_path }
            format.js {
              render_with_info do |page|
                page.redirect_to root_path
              end
            }
          end
        else
          redirect_or_render_with_error(settings_path, "users.echo_account.change_password.wrong_password")
        end
      end
    rescue Exception => e
      log_message_error(e, "Error deleting account from user '#{current_user.id}'.")
    else
      log_message_info("User '#{current_user.id}' account has been sucessfully deleted.")
    end
  end

  def add_concernments
    concernments = params[:tag][:value]
    new_concernments = concernments.split(',').map!{|t|t.strip} - current_user.send("#{params[:context]}_tags".to_sym)
    all_concernments = current_user.send("#{params[:context]}_tags".to_sym) + new_concernments
    old_concernments_hash = current_user.send("#{params[:context]}_tags_hash".to_sym)
    begin
      previous_completeness = current_user.profile.percent_completed
      current_user.send("#{params[:context]}_tags=".to_sym, all_concernments)
      respond_to do |format|
        format.js do
          if current_user.save and current_user.profile.save
            current_completeness = current_user.profile.percent_completed
            if previous_completeness != current_completeness
              set_info("discuss.messages.new_percentage", :percentage => current_completeness)
            end
            new_concernments_hash = current_user.send("#{params[:context]}_tags_hash").to_a - old_concernments_hash.to_a
            render_with_info do |p|
              p.insert_html :bottom, "concernments_#{params[:context]}",
                            :partial => "users/concernments/concernment",
                            :collection => new_concernments_hash,
                            :locals => {:context => params[:context]}
              p << "$('#new_concernment_#{params[:context]}').reset();"
              p << "$('#concernment_#{params[:context]}_id').focus();"
            end
          else
            set_error current_user and render_with_error
          end
        end
      end
    rescue Exception => e
      log_message_error(e, "Error adding concernments '#{new_concernments}'.")
    else
      log_message_info("Concernments '#{new_concernments}' have been added sucessfully.")
    end
  end

  def delete_concernment
    begin
      previous_completeness = current_user.percent_completed
      current_user.send("#{params[:context]}_tags=", current_user.send("#{params[:context]}_tags") - [params[:tag]])
      current_user.save
      current_user.profile.save
      current_completeness = current_user.percent_completed
      if previous_completeness != current_completeness
        set_info("discuss.messages.new_percentage", :percentage => current_completeness)
      end

      respond_to do |format|
        format.js do
          render_with_info do |p|
            p.remove "#{params[:context]}_#{params[:id]}"
          end
        end
      end
    rescue Exception => e
      log_message_error(e, "Error deleting concernment '#{params[:tag]}'.")
    else
      log_message_info("Concernment '#{params[:tag]}' has been deleted sucessfully.")
    end
  end

  private

  def fetch_user
    @user = User.find(params[:id]) || current_user
  end

  def user_not_active?
    !@user.active
  end

end
