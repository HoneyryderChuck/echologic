module TranslationModule
  ################
  # TRANSLATIONS #
  ################

  #
  # Renders the new statement translation form when called
  #
  # Method:   GET
  # Response: JS
  #
  def new_translation
    @statement_document ||= @statement_node.document_in_preferred_language(@language_preference_list)
    if (is_current_document = @statement_document.id == params[:current_document_id].to_i) and
       !(already_translated = @statement_document.language_id == @locale_language_id)
      has_lock = acquire_lock(@statement_document)
      if @new_statement_document.nil?
        @new_statement_document ||= @statement_document.clone
        @new_statement_document.title = nil
        @new_statement_document.text = nil
        @new_statement_document.language_id = @locale_language_id
        @new_statement_document.statement_history.old_document ||= @statement_document
        @new_statement_document.statement_history.action ||= StatementAction["translated"]
      end
    end
    if !is_current_document
      set_statement_info('discuss.statements.statement_updated')
      render_statement_with_info
    elsif already_translated
      set_statement_info('discuss.statements.already_translated')
      render_statement_with_info
    elsif !has_lock
      set_info('discuss.statements.being_edited')
      render_statement_with_info
    else
      render_template 'statements/new_translation'
    end
  end

  #
  # Creates a translation of a statement according to the fields from a form that was submitted
  #
  # Method:   POST
  # Params:   new_statement_document: hash
  # Response: JS
  #
  def create_translation
    translated = false
    begin
      attrs = params[statement_node_symbol]
      new_attrs_doc = attrs[:statement_attributes][:statement_documents_attributes]["0"]
      locked_at = new_attrs_doc.delete(:locked_at) if new_attrs_doc
        
      # Updating the statement
      holds_lock = true
      
      old_statement_document = StatementDocument.find(new_attrs_doc[:statement_history_attributes][:old_document_id])
      StatementNode.transaction do
        
        holds_lock = holds_lock?(old_statement_document, locked_at)
        if holds_lock
          new_attrs_doc.merge!({:current => true, :language_id => @locale_language_id})
          new_attrs_doc[:statement_history_attributes].merge!({:author_id => current_user.id})

          @statement_node.update_attributes(attrs)
        end
        @new_statement_document = StatementDocument.new(new_attrs_doc)
      end

      # Rendering response
      if !holds_lock
        being_edited
      elsif @statement_node.valid?
        old_statement_document.unlock
        @statement_document = @statement_node.document_in_preferred_language(@language_preference_list)
        set_statement_info(@statement_document)
        show_statement
      else
        set_error(@statement_node, :only => ["statement.statement_documents.title", 
                                             "statement.statement_documents.text"])
        @statement_document = @statement_node.document_in_preferred_language(@language_preference_list)
        render_statement_with_error :template => 'statements/new_translation'
      end
    rescue Exception => e
      log_message_error(e, "Error translating statement node '#{@statement_node.id}'.") do
        load_ancestors and flash_error and render :template => 'statements/new_translation'
      end
    else
      log_message_info("Statement node '#{@statement_node.id}' has been translated sucessfully.") if translated
    end
  end
end