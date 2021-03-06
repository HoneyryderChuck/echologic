class StatementsController < ApplicationController
  helper :echo
  include EchoHelper

  # remodelling the RESTful constraints, as a default route is currently active
  # FIXME: the echo and unecho actions should be accessible via PUT/DELETE only,
  #        but that is currently undoable without breaking non-js requests. A
  #        solution would be to make the "echo" button a real submit button and
  #        wrap a form around it.
  verify :method => :get, :only => [:index, :show, :new, :edit, :category, :new_translation]
  verify :method => :post, :only => [:create]
  verify :method => :put, :only => [:update,:create_translation]
  verify :method => :delete, :only => [:destroy]

  # the order of these filters matters. change with caution.
  before_filter :fetch_statement, :only => [:show, :edit, :update, :echo, :unecho, :new_translation,:create_translation,:destroy]
  before_filter :fetch_category, :only => [:index, :new, :show, :edit, :update, :new_translation,:create_translation,:destroy]

  before_filter :require_user, :except => [:index, :category, :show]

  # make custom URL helper available to controller
  include StatementHelper

  # authlogic access control block
  access_control do
    allow :editor
    allow anonymous, :to => [:index, :show, :category]
    allow logged_in, :only => [:index, :show, :echo, :unecho, :new_translation,:create_translation]
    allow logged_in, :only => [:new, :create], :unless => :is_question?
    allow logged_in, :only => [:edit, :update], :if => :may_edit?
    allow logged_in, :only => [:destroy], :if => :may_delete?
  end

  # FIXME: I tink this method is never used - it should possibly do nothing, or redirect to category...
  def index
    @statements = statement_class.published(current_user.has_role?(:editor)).by_supporters.paginate(statement_class.default_scope.merge(:page => @page, :per_page => 6))
    respond_to do |format|
      format.html { render :template => 'statements/questions/index' }
    end
  end



  # TODO use find or create category tag?
  # displays all questions in a category
  def category
    @value    = params[:value] || ""
    @page     = params[:page]  || 1

    @current_language_keys = current_language_keys

    if @value.blank?
      statements_not_paginated = statement_class
      statements_not_paginated = statements_not_paginated.from_context(TaoTag.valid_contexts(StatementNode.name)).from_tags(params[:id]) if params[:id]
      statements_not_paginated = statements_not_paginated.published(current_user && current_user.has_role?(:editor)).by_supporters.by_creation
    else
      statements_not_paginated = search(@value, {:tag => params[:id], :auth => (current_user && current_user.has_role?(:editor)) })
    end

    #additional step: to filter statements with a translated version in the current language
    statements_not_paginated = statements_not_paginated.select{|s| !(@current_language_keys & s.statement_documents.collect{|sd| sd.language_id}).empty?}

    @count    = statements_not_paginated.size

    @category = Tag.find_or_create_by_value(params[:id])
    @statements = statements_not_paginated.paginate(:page => @page, :per_page => 6)

    respond_to do |format|
      format.html {render :template => 'statements/questions/index'}
      format.js {render :template => 'statements/questions/questions'}
    end
  end




  # TODO visited! throws error with current fixtures.

  def show
    current_user.visited!(@statement) if current_user

    # store last statement (for cancel link)
    session[:last_statement] = @statement.id

    @current_language_keys = current_language_keys

    # prev / next functionality
    unless @statement.children.empty?
      child_type = ("current_" + @statement.class.expected_children.first.to_s.underscore).to_sym
      session[child_type] = @statement.children.by_supporters.collect { |c| c.id }
    end

    # Get document to show and redirect if not found
    @statement_document = @statement.translated_document(current_language_keys)
    if @statement_document.nil?
      redirect_to(discuss_search_path)
      return
    end

    #test for special links
    @original_language_warning = (!current_user.nil? and current_user.spoken_languages.empty? and
                                  current_language_key != @statement.statement.original_language.id)

    @translation_permission = (!current_user.nil? and !current_user.spoken_languages.blank?  and #1.we have a current user that speaks languages
                               !current_user.mother_tongues.blank?                           and #2.we ensure ourselves that the user has a mother tongue
                               !@statement_document.language.code.eql?(params[:locale])      and #3.current text language is different from the current language, which would mean there is no translated version of the document yet in the current language
                               current_user.mother_tongues.collect{|l| l.code}.include?(params[:locale])                       and #4.application language is the current user's mother tongue
                               current_user.spoken_languages.map{|sp| sp.language}.uniq.include?(@statement_document.language) and #5.user knows the document's language
                               #6. user has language level greater than intermediate
                               %w(intermediate advanced mother_tongue).include?(current_user.spoken_languages.select{|sp| sp.language == @statement_document.language}.first.level.code))

    # when creating an issue, we save the flash message within the session, to be able to display it here
    if session[:last_info]
      @info = session[:last_info]
      flash_info
      session[:last_info] = nil
    end

    # find alle child statements, which are published (except user is an editor) sorted by supporters count, and paginate them
    @page = params[:page] || 1

    @children = children_for_statement @current_language_keys
    respond_to do |format|
      format.html {
        render :template => 'statements/show' } # show.html.erb
      format.js   {
        render :template => 'statements/show' } # show.js.erb
    end
  end

  # Called if user supports this statement. Updates the support field in the corresponding
  # echo object.
  def echo
    return if @statement.question?
    current_user.supported!(@statement)
    @current_language_keys = current_language_keys
    respond_to do |format|
      format.html { redirect_to @statement }
      format.js { render :template => 'statements/echo' }
    end
  end

  # Called if user doesn't support this statement any longer. Sets the supported field
  # of the corresponding echo object to false.
  def unecho
    return if @statement.question?
    current_user.echo!(@statement, :supported => false)
    @current_language_keys = current_language_keys
    respond_to do |format|
      format.html { redirect_to @statement }
      format.js { render :template => 'statements/echo' }
    end
  end

  def new_translation
#     @new_statement_document = StatementDocument.new(:language_id => StatementDocument.languages(params[:locale]).id)
    @statement_document ||= @statement.translated_document(current_user.language_keys)
    @new_statement_document ||= @statement.add_statement_document({:language_id => current_language_key})
#     @statement.add_statement_document
    respond_to do |format|
      format.html { render :template => 'statements/translate' }
      format.js {
        render :update do |page|
          page.replace('summary', :partial => 'statements/translate')
          page << "makeRatiobars();"
          page << "makeTooltips();"
          page << "roundCorners();"
        end
      }
    end
  end

  def create_translation
    attrs = params[statement_class_param]
    attrs[:state] = StatementNode.state_lookup[:published] unless statement_class == Question
    doc_attrs = attrs.delete(:new_statement_document)
    doc_attrs[:author_id] = current_user.id
    doc_attrs[:language_id] = current_language_key
    @new_statement_document = @statement.add_statement_document(doc_attrs)
    respond_to do |format|
      if @statement.save
        set_statement_node_info("discuss.messages.translated",@statement)
        @current_language_keys = current_language_keys
        @statement_document = @new_statement_document
        format.html { flash_info and redirect_to url_for(@statement) }
        format.js   {
          render_with_info do |page|
            page.replace('context', :partial => 'statements/context', :locals => { :statement => @statement})
            page.replace('summary', :partial => 'statements/summary', :locals => { :statement => @statement, :statement_document => @statement_document})
            page << "makeRatiobars();"
            page << "makeTooltips();"
          end
        }
      else
        @statement_document = StatementDocument.find(doc_attrs[:translated_document_id])
        set_error(@new_statement_document)
        format.html { flash_error and render :template => 'statements/translate' }
        format.js   { show_error_messages(@new_statement_document) }
      end
    end
  end

  # renders form for creating a new statement
  def new
    @statement ||= statement_class.new(:parent => parent, :category_id => @category.id)
    @statement_document ||= StatementDocument.new

    @current_language_keys = current_language_keys
    @current_language_key = current_language_key
    # TODO: right now users can't select the language they create a statement in, so current_user.languages_keys.first will work. once this changes, we're in trouble - or better said: we'll have to pass the language_id as a param
    respond_to do |format|
      format.html { render :template => 'statements/new' }
      format.js {
        render :update do |page|
          if @statement.kind_of?(Question)
            page.remove 'search_container'
            page.remove 'new_question'
            page.replace 'questions_container', :partial => 'statements/new'
          else
            page.replace 'children', :partial => 'statements/new'
          end
          page.replace('context',
                       :partial => 'statements/context',
                       :locals => { :statement => @statement.parent}) if @statement.parent
          page.replace('discuss_sidebar',
                       :partial => 'statements/sidebar',
                       :locals => { :statement => @statement.parent})
          # Direct JS
          page << "makeRatiobars();"
          page << "makeTooltips();"
        end
      }
    end
  end

  # actually creates a new statement
  def create
    attrs = params[statement_class_param].merge({:creator_id => current_user.id})
    attrs[:state] = StatementNode.state_lookup[:published] unless statement_class == Question
    doc_attrs = attrs.delete(:statement_document)
    # TODO: as soon as there is the possibility, that the language is passed with the form data (e.g. the user made a translation) we can't rely on the users first language_key anymore
    # FIXME: find a way to move more stuff into the models
    @statement = statement_class.new(attrs)
    @statement.create_statement(:original_language_id => current_language_key)
    @statement_document = @statement.add_statement_document(doc_attrs)
    tao_tag = TaoTag.new(:tag_id => Tag.find(attrs[:category_id]).id, :tao_type => StatementNode.name, :context_id => EnumKey.find_by_code("topic").id)
    respond_to do |format|
      if @statement.save
        tao_tag.tao = @statement
        tao_tag.save
        @current_language_keys = current_language_keys
        set_statement_node_info("discuss.messages.created",@statement)
        current_user.supported!(@statement)
        #load current created statement to session
        if @statement.parent
          type = @statement.class.to_s.underscore
          key = ("current_" + type).to_sym
          session[key] = @statement.parent.children.map{|s|s.id}
        end
        @children = children_for_statement
        format.html { flash_info and redirect_to url_for(@statement) }
        format.js   {
          #session[:last_info] = @info # save @info so it doesn't get lost during redirect
          render_with_info do |page|
            if @statement.kind_of?(Question)
              page.insert_html :top , 'function_container',
                               :partial => 'statements/summary',
                               :locals => { :statement => @statement, :statement_document => @statement_document}
              page.insert_html :top , 'function_container',
                               :partial => 'statements/sidebar',
                               :locals => { :statement => @statement}
              page.insert_html :top , 'function_container',
                               :partial => 'statements/context',
                               :locals => { :statement => @statement}
            else
              page.replace('context',
                           :partial => 'statements/context',
                           :locals => { :statement => @statement})
              page.replace('discuss_sidebar',
                           :partial => 'statements/sidebar',
                           :locals => { :statement => @statement})
              page.replace('summary',
                           :partial => 'statements/summary',
                           :locals => { :statement => @statement, :statement_document => @statement_document})
            end
            page.replace 'new_statement',
                         :partial => 'statements/children',
                         :statement => @statement,
                         :children => @children
            # Direct JS
            page << "makeRatiobars();"
            page << "makeTooltips();"
          end
        }
      else
        @current_language_key = current_language_key
        set_error(@statement_document)
        format.html { flash_error and render :template => 'statements/new' }
        format.js   { show_error_messages(@statement_document)}
      end
    end
  end

  # renders a form to edit statements
  def edit
    @statement_document ||= @statement.translated_document(current_language_keys)
    @current_language_key = current_language_key
    respond_to do |format|
      format.html { render :template => 'statements/edit' }
      format.js { replace_container('summary', :partial => 'statements/edit') }
    end
  end

  # actually update statements
  def update
    attrs = params[statement_class_param]
    attrs[:statement_document][:author] = current_user
    attrs_doc = attrs.delete(:statement_document)
    respond_to do |format|
      if @statement.update_attributes!(attrs) && @statement.translated_document(current_user.language_keys).update_attributes!(attrs_doc)
        set_statement_node_info("discuss.messages.updated",@statement)
        format.html { flash_info and redirect_to url_for(@statement) }
        format.js   { show }
      else
        @current_language_key = current_language_key
        set_error(@statement.document)
        format.html { flash_error and redirect_to url_for(@statement) }
        format.js   { show_error_messages }
      end
    end
  end

  # destroys a statement
  def destroy
    @statement.destroy
    set_statement_node_info("discuss.messages.deleted",@statement)
    flash_info and redirect_to :controller => 'questions', :action => :category, :id => @category.value
  end

  # processes a cancel request, and redirects back to the last shown statement
  def cancel
    redirect_to url_f(StatementNode.find(session[:last_statement]))
  end

  #
  # PRIVATE
  #
  private

  def fetch_statement
    @statement ||= statement_class.find(params[:id]) if params[:id].try(:any?) && params[:id] =~ /\d+/
  end

  # Fetch current category based on various factors.
  # If the category is supplied as :id, render action 'index' no matter what params[:action] suggests.
  def fetch_category
    @category = if params[:category] # i.e. /discuss/questions/...?category=<tag>
                  Tag.find_by_value(params[:category])
                elsif params[:category_id] # happens on form-based POSTed requests
                  Tag.find(params[:category_id])
                elsif parent || (@statement && ! @statement.new_record?) # i.e. /discuss/questions/<id>
                  (!@statement.nil? ? @statement.tags.first : parent.tags.first)
                else
                  nil
                end or redirect_to :controller => 'discuss', :action => 'index'
  end

  # returns the statement class, corresponding to the controllers name
  def statement_class
    params[:controller].singularize.camelize.constantize
  end

  # Checks if the current controller belongs to a question
  # FIXME: isn't this possible to solve over statement.quesion? already?
  def is_question?
    params[:controller].singularize.camelize.eql?('Question')
  end

  def may_edit?
    current_user.may_edit?(@statement)
  end

  def may_delete?
    current_user.may_delete?(@statement)
  end

  def statement_class_param
    statement_class.name.underscore.to_sym
  end

  def set_statement_node_info(string, statement_node)
    set_info(string, :type => I18n.t("discuss.statements.types.#{statement_class_dom_id(statement_node).downcase}"))
  end

  def parent
    statement_class.valid_parents.each do |parent|
      parent_id = params[:"#{parent.to_s.underscore.singularize}_id"]
      return parent.to_s.constantize.find(parent_id) if parent_id
    end ; nil
  end

  # private method, that collects all children, sorted and paginated in the way we want them to
  def children_for_statement(language_keys = current_language_keys, page = @page)
    children = @statement.children.published(current_user && current_user.has_role?(:editor)).by_supporters
    #additional step: to filter statements with a translated version in the current language
    children = children.select{|s| !(language_keys & s.statement_documents.collect{|sd| sd.language_id}).empty?}
    children.paginate(StatementNode.default_scope.merge(:page => page, :per_page => 5))
  end

  def search (value, opts = {})
    StatementNode.search_statements("Question", value, opts)
  end
end


