class MyEchoController < ApplicationController
  helper :profiles

  access_control do
    allow logged_in
  end

  def roadmap
    respond_to do |format|
      format.html
    end
  end

  def profile
    @profile = @current_user.profile
    @user    = @current_user
    @locale_language_id = locale_language_id
    render
  end

  def welcome
    render
  end

  def settings
    begin
      @profile = @current_user.profile
      @user    = @current_user
      @current_user.update_social_accounts
      render
    rescue RpxService::RpxServerException
      redirect_or_render_with_error(base_url, "application.remote_error")
    rescue Exception => e
      log_message_error(e, "Error showing settings")
    end
  end

  %w(change_email change_password delete_account).each do |action_name|
    class_eval %(
      def #{action_name}
        respond_to do |format|
          format.html {  }
          format.js {
            render :template => 'users/echo_account/insert_form', :locals => {:partial => "users/users/#{action_name}"}
          }
        end
      end
    )
  end


  {'notification' => ['newsletter','activity','drafting'], 'permission' => ['authorship']}.each do |type, contents|
    contents.each do |content|
      class_eval %(
        def set_#{content}_#{type}
          @user = User.find(params[:id])
          notify = params.has_key?(:notify)
          @user.#{content}_#{type} = notify ? 1 : 0
          @user.save
          respond_to do |format|
            format.js do
              set_info("users.#{type.pluralize}.#{content}." + (notify ? 'turned_on' : 'turned_off'))
              render_with_info do
                replace_content('#{content}_#{type}_element',
                                :partial => 'users/components/check',
                                :locals => {:type => '#{type}', :content => '#{content}'})
              end
            end
          end
        end
      )
    end
  end

end
