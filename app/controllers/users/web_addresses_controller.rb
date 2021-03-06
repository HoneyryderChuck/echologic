class Users::WebAddressesController < ApplicationController

  before_filter :require_user

  helper :profile

  access_control do
    allow logged_in
  end

  # Show the web profile with the given id.
  # method: GET
  def show
    @web_address = WebAddress.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.js do
        replace_content(dom_id(@web_address), :partial => 'web_address')
      end
    end
  end

  # Show the new template for web profiles. Currently unused.
  # method: GET
  def new
    @web_address = WebAddress.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # Show the edit template for the specified web profile.
  # method: GET
  def edit
    @user = @current_user
    @web_address = WebAddress.find(params[:id])

    respond_to do |format|
      format.js do
        replace_content(dom_id(@web_address), :partial => 'edit')
      end
    end
  end

  # Create new web profile for the current user.
  # method: POST
  def create
    @web_address = WebAddress.new(params[:web_address])
    @web_address.user_id = @current_user.id

    previous_completeness = @web_address.profile.percent_completed
    respond_to do |format|
      format.js do
        if @web_address.save
          current_completeness = @web_address.profile.percent_completed
          set_info("discuss.messages.new_percentage", :percentage => current_completeness) if previous_completeness != current_completeness

          render_with_info do |p|
            p.insert_html :bottom, 'web_address_list', :partial => 'users/web_addresses/web_address'
            p << "$('#new_web_address').reset();"
	          p << "$('#web_address_type_id').focus();"
          end
        else
          show_error_messages(@web_address)
        end
      end
    end
  end

  # Update the web profiles attributes
  # method: PUT
  def update
    @web_address = WebAddress.find(params[:id])

    respond_to do |format|
      format.js do
        if @web_address.update_attributes(params[:web_address])
          replace_content(dom_id(@web_address), :partial => @web_address)
        else
          show_error_messages(@web_address)
        end
      end
    end
  end

  # Remove the web profile specified through id
  # method: DELETE
  def destroy
    @web_address = WebAddress.find(params[:id])
    id = @web_address.id
    previous_completeness = @web_address.profile.percent_completed
    @web_address.destroy
    current_completeness = @web_address.profile.percent_completed
    set_info("discuss.messages.new_percentage", :percentage => current_completeness) if previous_completeness != current_completeness

    respond_to do |format|
      format.js do

        # sorry, but this was crap. you can't add additional js actions like this...
        # either use a rjs, a js, or a render :update block
        #remove_container "web_profile_#{id}"
        render_with_info do |p|
          p.remove dom_id(@web_address)
        end
      end
    end
  end

end
