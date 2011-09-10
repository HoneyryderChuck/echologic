class StatementImagesController < ApplicationController
  
  verify :method => :get, :only => [:new, :edit, :load, :reload]
  verify :method => :post, :only => [:create] 
  verify :method => :put, :only => [:update]
  
  before_filter :fetch_statement_image, :except => [:new, :create, :load]
  before_filter :fetch_statement_node, :only => [:edit, :reload]
  
  access_control do
    allow :admin, :editor, logged_in
  end
  
  #
  # Renders a form to uplaoad an image
  #
  # Method:   GET
  # Response: JS
  #
  def new
    @statement_image = StatementImage.new
    @pending = PendingAction.create
    respond_to_js :template_js => 'statement_images/new'
  end

  #
  # creates image and associates it with a certain pending action
  #
  # Method:   POST
  # Params:   statement_image: hash
  # Response: JS
  #
  def create
    image = StatementImage.create(params[:statement_image])
    PendingAction.find(params[:pending_action_id]).update_attributes(:action => {:image_id => image.id}.to_json)
    respond_to(:html,:js)
  end

  #
  # Renders a form to insert the current statement's image.
  #
  # Method:   GET
  # Params:   id: integer, node_id: integer
  # Response: JS
  #
  def edit
    respond_to_js :template_js => 'statement_images/edit'
  end
  
  
  #
  # Updates statement's image
  #
  # Method:   POST
  # Params:   statement_image: hash
  # Response: JS
  #
  def update
    @statement_image.update_attributes(params[:statement_image])
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  #
  # After uploading the image, load the picture on the form
  # loading:
  #  1. login_container with users picture as profile link
  #  2. picture container of the form
  #
  # Method:   GET
  # Response: JS
  #
  def load
    @pending = PendingAction.find(params[:id])
    @statement_image = StatementImage.find(JSON.parse(@pending.action)['image_id'])
    respond_to do |format|
      if @statement_image.image.exists?
        set_info 'discuss.messages.image_uploaded', :type => I18n.t("discuss.statements.types.#{params[:type]}")
        format.js {
          render_with_info do |page|
            page << "$('#statements form.#{params[:type]} .image_container .image').replaceWith('#{render :partial => 'statement_images/image'}');"
            page << "$('#statements form.#{params[:type]} #statement_node_statement_image_id').val('#{@pending.id}');"            
          end
        }
      else
        format.js { set_error 'discuss.statements.upload_image.error' and render_with_error }
      end
    end
  end
  
  #
  # After uploading the image, this has to be reloaded.
  # Reloading:
  #  1. login_container with users picture as profile link
  #  2. picture container of the profile
  #
  # Method:   GET
  # Response: JS
  #
  def reload
    respond_to do |format|
      if @statement_image.image.exists? and @statement_image.image.updated_at != params[:date].to_i
        set_info 'discuss.messages.image_uploaded', :type => I18n.t("discuss.statements.types.#{@statement_node.u_class_name}")
        format.js {
          render_with_info do |page|
            page << "$('#statements div.#{dom_class(@statement_node)} .image_container .image').replaceWith('#{render :partial => 'statement_images/image'}');"
            page << "$('#statements div.#{dom_class(@statement_node)} .image_container .upload_link').remove();" if !current_user or !current_user.may_edit?(@statement_node)            
          end
        }
      else
        format.js { set_error 'discuss.statements.upload_image.error' and render_with_error }
      end
    end
  end
  
  private
  
  def fetch_statement_image
    @statement_image = StatementImage.find(params[:id])
  end
  
  def fetch_statement_node
    @statement_node = StatementNode.find(params[:node_id])
  end
end
