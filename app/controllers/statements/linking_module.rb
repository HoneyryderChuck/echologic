module LinkingModule

  #
  # Auto completion to get all statements with certain terms in them.
  #
  # Method:   GET
  # Response: JS
  #
  def auto_complete_for_statement_title
    type = params[:type]
    linkable_types = type.classify.constantize.linkable_types.map(&:to_s)

    parent_node = StatementNode.find(params[:parent_id])

    # Excluding content belonging to the same subtree (including the root node of the subtree itself)
    conditions = ["(s.root_id != ? OR
                   s.id NOT IN (select id FROM statement_nodes n where n.lft >= ? AND n.rgt <= ? AND n.root_id = ?))",
                   parent_node.root_id, parent_node.lft, parent_node.rgt, parent_node.root_id]

    statement_nodes = search_statement_nodes(:param => 'statement_id',
                                             :search_term => params[:q],
                                             :types => linkable_types,
                                             :language_ids => [params[:code] || locale_language_id],
                                             :node_conditions => [conditions]).all(:limit => params[:limit] || 5)
    documents = search_statement_documents(:statement_ids => statement_nodes.map(&:statement_id))

    content = statement_nodes.map(&:statement_id).uniq.map{ |id|
      "#{documents[id].title}|#{id}"
    }.join("\n")

    render :text => content
  end

  #
  # Gets the statement data needed to fill the new statement node form and successfully link it with the statement.
  # This is called when entering some word of the title into the title field and pressing the Link button.
  #
  # Method:   GET
  # Response: JSON
  #
  def link_statement
    @statement ||= Statement.find(params[:id])
    @statement_document ||= @statement.document_in_language(params[:code]||locale_language_id)
    if @statement_document
      @content = {:id => @statement.id,
                  :title => @statement_document.title,
                  :editorial_state => @statement.editorial_state_id,
                  :tags => @statement.topic_tags,
                  :text => @statement_document.text}
      if @statement.has_data?
        @content[:content_type] = @statement.info_type.code
        @content[:external_url] = @statement.external_url.info_url
      end
      render :json => @content.to_json
    else
      render :json => {:error => I18n.t("discuss.statements.no_document_in_language")}
    end
  end

  #
  # Gets the statement data needed to fill the new statement node form and successfully link it with the statement.
  # This is called when entering a URL into the title field and pressing the Link button.
  #
  # Method:   GET
  # Response: JSON
  #
  def link_statement_node
    @statement = @statement_node.statement
    @type_to_link = params[:type].to_s.classify.constantize
    @parent_node = StatementNode.find(params[:parent_id])
    if @type_to_link.linkable_types.include? @statement_node.class.name.to_sym and
      !@statement_node.parent_node.id.eql?(@parent_node.target_id)
      link_statement
    else
      render :json => {:error => I18n.t("discuss.statements.cannot_be_linked")}
    end
  end

end