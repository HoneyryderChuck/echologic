module PublishableModule


  ###########
  # ACTIONS #
  ###########

  # Shows all current users' existing questions
  #
  # Method:   GET
  # Params:   value: string, id (category): string
  # Response: JS
  #
  def my_questions
    @page     = params[:page]  || 1

    questions_not_paginated = Question.by_creator(current_user).by_creation

    @questions = questions_not_paginated.paginate(:page => @page, :per_page => 5)
    @statement_documents = search_statement_documents :statement_ids => @questions.map(&:statement_id)

    respond_to_js :template => 'statements/questions/my_questions', :template_js => 'statements/questions/my_questions'
  end


  # Shows all the existing debates according to the given search string and a possible category.
  #
  # Method:   GET
  # Params:   value: string, id (category): string
  # Response: JS
  #
  def index
    @value    = params[:search_terms] || ""
    @page     = params[:page].blank? ? 1 : params[:page]
    @page_count = params[:page_count].blank? ? 1 : params[:page_count]
    @per_page = @page_count.to_i * QUESTIONS_PER_PAGE

    @origin = @value.blank? ? 'ds' : "sr#{Breadcrumb.encode_terms(@value)}" 
    @origin << "|#{params[:page_count].blank? ? @page : params[:page_count]}"
    @origin = @origin

    statement_nodes_not_paginated = search_statement_nodes :search_term => @value

    @count    = statement_nodes_not_paginated.count
    @statement_nodes = statement_nodes_not_paginated.scoped(:include => [:echo, {:statement => :statement_image}]).paginate(:page => @page, :per_page => @per_page)
    @statement_documents = search_statement_documents(:statement_ids => @statement_nodes.map(&:statement_id),
                                                      :more => ["text"])

    respond_to_js :template => 'statements/questions/index',
                  :template_js => 'statements/questions/questions'
  end

  # publishes the statement
  #
  # Method:   PUT
  # Response: JS
  #
  def publish
    begin
      StatementNode.transaction do
        
        respond_to do |format|
          if @statement_node.publish!
            format.html {params[:in] == 'mi' ? my_questions : show}
            format.js do
              set_info("discuss.statements.published")
              render_with_info do |page|
                if params[:in] == 'summary'
                  page << "$('#statements .#{dom_class(@statement_node)} .edit_text_button').remove();"
                  page << "$('#statements .#{dom_class(@statement_node)} .publish_text_button').remove();"
                elsif params[:in] == 'mi'
                  @statement_documents = search_statement_documents :statement_ids => [@statement_node.statement_id]
                  page.replace(dom_id(@statement_node),
                               :partial => 'statements/questions/my_question',
                               :locals => {:my_question => @statement_node,
                                           :statement_document => @statement_documents[@statement_node.statement_id]})
                else
                  page << "$('##{dom_id(@statement_node)} .publish_button').remove();"
                end
              end
            end
          else
            set_error(@statement_node.statement)
            format.html{flash_error and params[:in] == 'mi' ? my_questions : show}
            format.js do
              set_error @statement_node and render_with_error
            end
          end
        end
      end
    rescue Exception => e
      log_message_error(e, "Error publishing statement node '#{@statement_node.id}'.") do
        if params[:in] == 'summary'
          flash_error and redirect_to statement_node_url(@statement_node)
        else
          flash_error and redirect_to my_questions_url
        end
      end
    else
      log_message_info("Statement node '#{@statement_node.id}' has been published sucessfully.")
    end
  end
  

  protected

  def is_publishable?
    @statement_node.publishable?
  end
end