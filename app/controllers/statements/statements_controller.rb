class StatementsController < ApplicationController

  verify :method => :get, :only => [:index, :show, :new, :edit, :category, :new_translation,
                                    :more, :children, :authors, :add, :ancestors, :descendants, :social_widget,
                                    :auto_complete_for_statement_title, :link_statement, :link_statement_node]
  verify :method => :post, :only => [:create, :share]
  verify :method => :put, :only => [:update, :create_translation]
  verify :method => :delete, :only => [:destroy]

  # The order of these filters matters. change with caution.
  skip_before_filter :require_user, :only => [:category, :show, :more, :children, :add, :ancestors, :descendants,
                                              :redirect_to_statement, :auto_complete_for_statement_title]

  before_filter :fetch_statement_node, :except => [:category, :my_questions, :new, :create,
                                                   :auto_complete_for_statement_title, :link_statement]
  before_filter :fetch_statement_node_type, :only => [:new, :create]
  before_filter :load_node_environment, :except => [:new]
  before_filter :check_read_permission, :except => [:category, :my_questions, :new, :create,
                                                    :auto_complete_for_statement_title, :link_statement,
                                                    :link_statement_node]
  before_filter :redirect_if_approved_or_incorporated, :only => [:show, :edit, :update, :destroy,
                                                                 :new_translation, :create_translation,
                                                                 :echo, :unecho]
  before_filter :fetch_languages, :except => [:destroy, :redirect_to_statement, :ancestors]
  before_filter :check_write_permission, :only => [:echo, :unecho, :new, :new_translation]
  before_filter :check_empty_text, :only => [:create, :update, :create_translation]


  include PublishableModule
  before_filter :is_publishable?, :only => [:publish]
  include EchoableModule
  before_filter :is_echoable?, :only => [:echo, :unecho, :social_widget, :share]
  include TranslationModule
  include IncorporationModule
  before_filter :is_draftable?, :only => [:incorporate]
  include LinkingModule

  # Authlogic access control block
  access_control do
    allow :admin
    allow logged_in, :editor, :except => [:destroy]
    allow anonymous, :to => [:index, :show, :category, :more, :children, :authors, :add, :ancestors, :descendants]
  end

  ##############
  # ATTRIBUTES #
  ##############

  @@edit_locking_time = 1.hours

  # Shows a selected statement
  #
  # Method:   GET
  # Params:   id: integer
  # Response: HTTP or JS
  #
  def show

#    begin
      # Get document to show or redirect if not found
      @statement_document ||= @statement_node.document_in_preferred_language(@language_preference_list)
      if @statement_document.nil?
        redirect_to_url discuss_search_url, 'discuss.statements.no_document_in_language'
        return
      end

      # Record visited
      @statement_node.visited!(current_user) if current_user

      # Test for special links
      @set_language_skills_teaser = @statement_node.should_set_languages?(current_user,
                                                                          @locale_language_id,
                                                                          @statement_document.language_id)
      @translation_permission = @statement_node.original_language == @statement_document.language &&
                                @statement_node.translatable?(current_user,
                                                              @statement_document.language,
                                                              Language[params[:locale]])


      # Load siblings for navigation (prev/next) functionality
      load_siblings(@statement_node) if @node_environment.new_level?
      # If statement node is draftable, load the approved node
      load_approved_statement
      # Load all children to be rendered
      load_all_children
      # Load the discuss alternatives question (if we're in alternative mode)
      load_discuss_alternatives_question(@statement_node)

      render_template 'statements/show'
#    rescue Exception => e
#      log_error_home(e, "Error showing statement.")
#    end
  end

  #
  # Renders form for creating a new statement.
  #
  # Method:   GET
  # Params:   parent_id: integer
  # Response: JS
  #
  def new
    # load main variables with the default values
    @statement_node ||= StatementNode.new(:parent_id => params[:id], 
                                          :top_level => false, 
                                          :statement_attributes => {
                                            :editorial_state => StatementState[:published],
                                          })
    @statement_document ||= StatementDocument.new(:language_id => @locale_language_id,
                                                  :statement_history_attributes => {
                                                    :action => StatementAction["created"] 
                                                  })
    
    load_node_environment # environment can only be loaded after there is a statement node
    
    #search terms as tags
    if @statement_node_type.taggable?
      @statement_node.load_root_tags if @statement_node_type.is_top_statement?
      load_search_terms_as_tags(@node_environment.origin)
    end

    if @node_environment.new_level?
      set_parent_breadcrumb
      # set new breadcrumb
      if @statement_node_type.is_top_statement?
        load_origin_statement
      end
    end

    load_echo_info_messages if @statement_node.echoable?

    render_template 'statements/new'
  end



  #
  # Creates a new statement.
  #
  # Method:   POST
  # Params:   statement: hash
  # Response: HTTP or JS
  #
  def create
    created = false
    attrs = params[statement_node_symbol].merge({:creator_id => current_user.id})
    doc_attrs = attrs[:statement_attributes][:statement_documents_attributes]["0"]

    # send new permission tags to statement node to be handled on filter
    form_tags = attrs[:statement_attributes][:topic_tags] || ""
    attrs[:new_permission_tags] = filter_permission_tags(form_tags.split(","), :read_write)
    
    if attrs[:statement_id].present? # linked statement
      doc_attrs.clear
    else
      # add default parameters
      doc_attrs.merge!({:current => true})
      doc_attrs[:statement_history_attributes].merge!({:author_id => current_user.id})
      attrs[:statement_attributes].merge!({:original_language_id => doc_attrs[:language_id] || @locale_language_id})  
    end
    

    begin
      StatementNode.transaction do
        # Prepare in memory
        @statement_node ||= @statement_node_type.new(attrs)
  
        # Rendering
        if @statement_node.save
          created = true
          EchoService.instance.created(@statement_node)
          EchoService.instance.created(@statement_node.question) if @statement_node.question_id
          
          @statement_document = @statement_node.document_in_preferred_language(@language_preference_list)
          load_siblings @statement_node
          load_discuss_alternatives_question(@statement_node)
          load_all_children
  
          set_statement_info @statement_document
          show_statement do
            render :template => 'statements/create'
          end
        else
          @statement_document = doc_attrs.empty? ? @statement_node.document_in_preferred_language(@language_preference_list) : StatementDocument.new(doc_attrs)
          load_statement_node_errors
          render_statement_with_error :template => 'statements/new'
        end
      end
    rescue Exception => e
      log_message_error(e, "Error creating statement node.") do
        load_ancestors and flash_error and render :template => 'statements/new'
      end
    else
      log_message_info("Statement node has been created sucessfully.") if created
    end
  end


  #
  # Renders a form to edit the current statement.
  #
  # Method:   GET
  # Params:   id: integer
  # Response: JS
  #
  def edit
    @statement_document ||= @statement_node.document_in_preferred_language(@language_preference_list)

    if (is_current_document = (@statement_document.id == params[:current_document_id].to_i))
      has_lock = acquire_lock(@statement_document)
      @statement_document = @statement_document.clone if has_lock
      @statement_document.statement_history.old_document_id = params[:current_document_id].to_i
      @statement_document.statement_history.action = StatementAction["updated"] 
    end

    

    if !current_user.may_edit? @statement_node
      set_statement_info 'discuss.statements.cannot_be_edited'
      render_statement_with_info
    elsif !is_current_document
      set_statement_info 'discuss.statements.statement_updated'
      show
    elsif !has_lock
      set_info 'discuss.statements.being_edited'
      render_statement_with_info
    else
      render_template 'statements/edit'
    end
  end


  #
  # Updates statements
  #
  # Method:   POST
  # Params:   statement: hash
  # Response: JS
  #
  def update
    update = false
    begin
      attrs = params[statement_node_symbol]
      attrs_doc = attrs[:statement_attributes][:statement_documents_attributes]["0"]
      locked_at = attrs_doc.delete(:locked_at) if attrs_doc
        
      # send new permission tags to statement node to be handled on filter
      form_tags = attrs[:statement_attributes][:topic_tags] || ''
      attrs[:new_permission_tags] = filter_permission_tags(form_tags.split(","), :read_write)

      old_statement_document = StatementDocument.find(attrs_doc[:statement_history_attributes][:old_document_id])
      holds_lock = holds_lock?(old_statement_document, locked_at)
      
      if holds_lock
        StatementNode.transaction do
          # add default parameters
          attrs_doc.merge!({:current => true})
          attrs_doc[:statement_history_attributes].merge!({:author_id => current_user.id})
          
          if @statement_node.update_attributes(attrs)
            old_statement_document.current = false
            old_statement_document.unlock # also saves the document
            update = true
            @statement_document = @statement_node.document_in_preferred_language(@language_preference_list)
            set_statement_info(@statement_document)
            show_statement
          else
            @statement_document = StatementDocument.new(attrs_doc)
            load_statement_node_errors
            show_statement true
          end
        end
      else
        being_edited
      end

    rescue Exception => e
      log_error_statement(e, "Error updating statement node '#{@statement_node.id}'.")
    else
      log_message_info("Statement node '#{@statement_node.id}' has been updated sucessfully.") if update
    end
  end

  #
  # Processes a cancel request, and redirects back to the last shown statement_node
  #
  def cancel
    locked_at = params[:locked_at]
    @statement_document = @statement_node.document_in_preferred_language(@language_preference_list)
    @statement_document.unlock if holds_lock?(@statement_document, locked_at)
    show_statement
  end

  # Loads the authors of this statement to the view
  #
  # Method:   GET
  # Response: JS
  #
  def authors
    begin
      load_authors
      respond_to do |format|
        format.html{show}
        format.js {render :template => 'statements/authors'}
      end
    rescue Exception => e
      log_error_home(e, "Error loading authors of statement node #{@statement_node ? @statement_node.id : params[:id]}.")
    end
  end

  #
  # Loads a certain siblings pane that had been previously hidden.
  #
  # Method:   GET
  # Params:   id : parent node id ; type: string
  # Response: JS
  #
  def descendants
    @type = params[:type].to_s.camelize.to_sym
    @current_node = StatementNode.find(params[:current_node]) if params[:current_node]
#    begin
      if @type.eql? :Alternative
        @hub_type = "alternative"
        @type = params[:alternative_type].to_s.camelize.to_sym
        load_alternatives(1, -1, @type, :alternative_ids => [], :with_self => true)
      else
        @statement_node ? load_children(:type => @type, :per_page => -1) : load_roots(:node => @current_node, :per_page => -1)
      end
      

      respond_to do |format|
        format.html{
          if @current_node
            @statement_node = @current_node
            show
          else
            add
          end
        }
        format.js { render :template => @type.to_s.constantize.descendants_template }
      end
#    rescue Exception => e
#      log_error_home(e, "Error loading descendants of type #{@type}.")
#    end
  end

  #
  # Loads a certain children pane that had been previously hidden.
  #
  # Method:   GET
  # Params:   type: string
  # Response: JS
  #
  def children
    @type = params[:type].classify.to_sym
    begin
      load_children :type => @type
      respond_to do |format|
        format.html{show}
        format.js {
          @children_list_template = @type.to_s.constantize.children_list_template
          render :template => "statements/children"
        }
      end
    rescue Exception => e
      log_error_home(e, "Error loading children of type #{@type}.")
    end
  end


  #
  # Loads more children into the right children pane (lazy pagination).
  #
  # Method:   GET
  # Params:   page: integer, type: string
  # Response: JS
  #
  def more
    @type = params[:type].classify.to_sym
    @page = params[:page] || 1
    @per_page = MORE_CHILDREN
    @offset = @page.to_i == 1 ? TOP_CHILDREN : 0
    begin
      if @type.eql? :Alternative
        @child_type = @statement_node.class.alternative_types.first.to_s.underscore
        @offset =  TOP_ALTERNATIVES if @offset > 0
        load_alternatives @page, @per_page
        template = @statement_node.class.more_template
      else
        load_children :type => @type, :page => @page, :per_page => @per_page
        template = @type.to_s.constantize.more_template
      end
      respond_to do |format|
        format.html{show}
        format.js {render :template => template}
      end
    rescue Exception => e
      log_error_home(e, "Error loading more children of type #{@type}.")
    end
  end

  #
  # Shows add statement teaser page.
  #
  # Method:   GET
  # Params:   type: string
  # Response: HTTP or JS
  #
  def add
    @type = params[:type].to_s
    load_discuss_alternatives_question(@statement_node) if @node_environment.alternative_mode?(@node_environment.level)
    begin
      if @node_environment.new_level?
        if @statement_node # this is the teaser's parent (e.g.: 1212345/add/proposal)
          load_children_for_parent @statement_node, @type
        else # this is the question's teaser (e.g.: /add/question
          load_roots_to_session
        end
      end
      render_template('statements/add', true)
    rescue Exception => e
      log_error_home(e, "Error showing add #{@type} teaser.")
    end
  end


  #################
  # ADMIN ACTIONS #
  #################

  #
  # Destroys a statement_node.
  #
  # Method:   DELETE
  # Params:   id: integer
  # Response: HTTP
  #
  def destroy
    begin
      @statement_node.destroy
      set_statement_info("discuss.messages.deleted")
      flash_info
      redirect_to(@statement_node.parent_node ? statement_node_url(@statement_node.parent_node) : discuss_search_url)
    rescue Exception => e
      log_message_error(e, "Error deleting statement node '#{@statement_node.id}'.") do
        flash_error and redirect_to_statement
      end
    else
      log_message_info("Statement node '#{@statement_node.id}' has been deleted successfully.")
    end
  end

  ###############
  # REDIRECTION #
  ###############

  #
  # Redirects to a given statement
  #
  # Method:   GET
  # Params:   id: integer
  # Response: REDIRECT
  #
  def redirect_to_statement
    options = {}
      %w(origin bids al hub).each{|s| options[s.to_sym] = params[s.to_sym]}
    redirect_to statement_node_url(@statement_node.target_statement, options)
  end

  ###############
  # AUX ACTIONS #
  ###############

  #
  # Loads the ancestors' ids
  #
  # Method:   GET
  # Params:   id: integer
  # Response: JSON
  #
  def ancestors
    statement_nodes = @statement_node.self_and_ancestors
    @statement_ids = statement_nodes.map(&:id)
    @bids = []
    statement_nodes.each_with_index do |s, index|
      break if index > statement_nodes.length - 2
      @bids << "#{Breadcrumb.generate_key(statement_nodes[index+1].u_class_name)}#{s.id}"
    end
    respond_to do |format|
      format.json{render :json => {:sids => @statement_ids, :bids => @bids}}
    end
  end

  #############
  # PROTECTED #
  #############

  protected

  def load_alternatives(page = 1, per_page = TOP_ALTERNATIVES, type = :Alternative, opts={})
    @children ||= {}
    @children_documents ||= {}
    @children[type] = @statement_node.paginated_alternatives(page,
                                                             per_page,
                                                             {:language_ids => filter_languages_for_children,
                                                             :user => current_user}.merge(opts))
    @children_documents.merge!(search_statement_documents(:language_ids => filter_languages_for_children,
                                                          :statement_ids => @children[type].flatten.map(&:statement_id)))
  end

  #
  # Loads the children of the current statement
  #
  # Loads instance variables:
  # @children(Hash) : key   : class name (String)
  #                   value : an array of statement nodes (Array) or an URL (string)
  # @children_documents(Hash) : key   : statement_id (Integer)
  #                             value : document (StatementDocument)
  #
  def load_all_children
    @children ||= {}
    children_types = @statement_node.class.all_children_types(:visibility => true)
    if !children_types.empty?
      @children_documents ||= {}
     
      children_types.each do |klass, immediate_render|
        if @children[klass].nil?
          if immediate_render
            load_children :type => klass
          else
            @children[klass] ||= @statement_node.count_child_statements :language_ids => filter_languages_for_children,
                                                                        :user => current_user,
                                                                        :type => klass
          end
        end
      end
    end
    load_alternatives if @statement_node.class.has_alternatives?
  end

  #
  # Loads the children from a certain type of the current statement
  # opts attributes:
  # type (String : optional) : Type of child to load
  #
  # more info about attributes, please check paginated child statements documentation
  #
  # Loads instance variables:
  # @children(Hash) : key   : class name (String)
  #                   value : an array of statement nodes (Array) or an URL (string)
  # @children_documents(Hash) : key   : statement_id (Integer)
  #                             value : document (StatementDocument)
  #
  def load_children(opts)
    opts[:user] ||= current_user
    opts[:language_ids] ||= filter_languages_for_children
    @children ||= {}
    @children[opts[:type]] = @statement_node.paginated_child_statements(opts)
    @children_documents ||= {}
    @children_documents.merge!(search_statement_documents :language_ids => filter_languages_for_children,
                                                          :statement_ids => @children[opts[:type]].flatten.map(&:statement_id))
  end

  # aux function to load the children with the right set of languages
  def filter_languages_for_children
    # if no user or user doesn't have any language defined, show everything
    if current_user.nil? or current_user.spoken_languages.empty?
      nil
    else
      @language_preference_list
    end
  end

  # aux function to load the statements with the right set of languages
  def filter_languages(opts={})
    languages = @language_preference_list
    if opts[:node] and !opts[:node].new_record?
      # VERY IMP: remove statement original language if user doesn't speak it
      original_language = opts[:node].original_language
      languages -= [original_language.id] if languages.length > 1 and original_language.code.to_s != I18n.locale and
       (current_user.nil? or
       !current_user.sorted_spoken_languages.include?(original_language.id))
    end
    languages
  end

  #
  # Load the authors of the current statement.
  #
  # Loads instance variables:
  # @authors(Array[User])
  #
  def load_authors
    @authors = @statement_node.authors
  end


  #####################
  # Editing / Locking #
  #####################

  #
  # Returns true if the current user could successfully acquire the lock.
  #
  def acquire_lock(statement_document)
    StatementDocument.transaction do
      if statement_document.locked_by.nil?
        statement_document.lock(current_user)
      elsif current_user != statement_document.locked_by
        if statement_document.locked_at >= @@edit_locking_time.ago
          return false
        else
          statement_document.lock(current_user)
        end
      end
    end
    return true
  end

  #
  # Returns true if the current user still holds his original lock he acquired when starting to edit the statement.
  #
  def holds_lock?(statement_document, locked_at)
    statement_document.locked_by == current_user && statement_document.locked_at.to_s == locked_at
  end


  ###########
  # FILTERS #
  ###########

  private

  #
  # Gets the correspondent statement node to the id that is given in the request.
  #
  # Loads instance variables:
  # @statement_node(StatementNode)
  #
  def fetch_statement_node
    @statement_node ||= StatementNode.find(params[:id], :include => :echo) if params[:id].try(:any?) && params[:id] =~ /\d+/
  end

  #
  # Gets the type of a new statement.
  #
  # Loads instance variables:
  # @statement_node_type(Class)
  #
  def fetch_statement_node_type
    @statement_node_type = params[:type] ? params[:type].to_s.classify.constantize : nil
  end

  def load_node_environment
    @node_environment = NodeEnvironment.new(@statement_node, @statement_node_type, params[:nl], params[:bids], params[:origin], params[:al], params[:hub], params[:cs], params[:sids])  
  end

  #
  # Checks if the user can access this very statement
  #
  def check_statement_permissions
    # check if the user has permissions to read this statement
    if @statement_node and !check_tag_permissions(@statement_node.root.topic_tags, false)
      redirect_to_url discuss_search_url, 'discuss.statements.read_permission'
      return
    end
  end

  #
  # Redirect to parent if incorporable is approved or already incorporated.
  #
  def redirect_if_approved_or_incorporated
    begin
      if @statement_node.incorporable? && (@statement_node.approved? || @statement_node.incorporated?)
        if @statement_node.approved?
          set_info("discuss.statements.see_parent_if_approved")
        else
          set_info("discuss.statements.see_parent_if_incorporated")
        end
        respond_to do |format|
          flash_info
          format.html { redirect_to statement_node_url @statement_node.parent_node }
          format.js do
            render :update do |page|
              page.redirect_to statement_node_url @statement_node.parent_node
            end
          end
        end
        return
      end
    rescue Exception => e
      log_error_home(e,"Error running redirect approved/incorporated IP filter")
    end
  end

  #
  # Loads the locale language and the language preference list.
  #
  # Loads instance variables:
  # @locale_language_id(Integer)
  # @language_preference_list(Array[Integer])
  #
  def fetch_languages
    @locale_language_id = locale_language_id
    @language_preference_list = language_preference_list
  end

  #
  # Checks if text that comes with the form is actually empty, even with the escape parameters from the iframe
  #
  def check_empty_text
    statement_attrs = params[statement_node_symbol][:statement_attributes]
    return if statement_attrs.blank?
    if statement_attrs.include? :statement_documents_attributes
      document_param = statement_attrs[:statement_documents_attributes]["0"]
      text = document_param[:text]
      document_param[:text] = "" if text.eql?('<br>')
    end
  end

  #
  # Returns the statement node corresponding symbol (:question, :proposal...).
  #
  def statement_node_symbol
    @symbol ||= @statement_node_type.nil? ? @statement_node.u_class_name.to_sym : :statement_node
  end

  #
  # Returns the parent statement node of the current statement.
  #
  def parent
    params.has_key?(:id) ? StatementNode.find(params[:id]) : nil
  end


  ######################
  # BREADCRUMB HELPERS #
  ######################


  #
  # Sets the breadcrumb of the current statement node's parent. Used only for new action.
  #
  # Loads instance variables:
  # @breadcrumb(Breadcrumb) (check build_breadcrumb documentation)
  # @bids(String) : breadcrumb keycodes separated by comma
  #
  def set_parent_breadcrumb
    return if @statement_node.parent_node.nil?
    parent_node = @statement_node.parent_node
    key = @node_environment.hub? ? @node_environment.hub.key : Breadcrumb.generate_key(@statement_node_type.name.underscore)
    
    @breadcrumb = Breadcrumb.new(key, parent_node, :language_ids => @language_preference_list, 
                                                   :origin => @node_environment.origin, 
                                                   :bids => @node_environment.bids, 
                                                   :final_key => @node_environment.hub)
    
    @bids = @node_environment.add_bid(@breadcrumb.key)
  end

  #
  # Sets the breadcrumbs for the current statement node view previous path.
  #
  # Loads instance variables:
  # @breadcrumbs(Array[Breadcrumb]) (check build_breadcrumb documentation)
  #
  def load_breadcrumbs

    if @node_environment.bids?
      # get bids into an array structure
      bids = @node_environment.bids
    else
      bids = []
      @ancestors.each_with_index do |ancestor, index|
        b_type = ancestor == @ancestors.last ?
                 @statement_node.u_class_name :
                 @ancestors[index+1].u_class_name
        bids << Struct.new(:key, :value).new(Breadcrumb.generate_key(b_type),ancestor.id)
      end if @ancestors
    end

    @breadcrumbs = []

    origin_bids = bids.select{|b|Breadcrumb.origin_keys.include?(b.key)}

    bids.each_with_index do |bid, index|
      origin = index > 0 ? origin_bids[index-1] : ''
      
      breadcrumb = Breadcrumb.new(bid.key, bid.value, :language_ids => @language_preference_list, 
                                                      :origin => origin, 
                                                      :bids => bids[0, bids.index(bid)])
      @breadcrumbs << breadcrumb
    end
  end

  ###############
  # PERMISSIONS #
  ###############

  #
  # Checks if the user has read permission on the current statement node (based on **tags).
  #
  def check_read_permission
    if @statement_node and !has_read_permission?(@statement_node.root.topic_tags)
      redirect_to_url discuss_search_url, 'discuss.statements.read_permission'
      return
    end
  end

  #
  # Checks whether the user is allowed to read a statement with the given tags.
  #
  def has_read_permission?(statement_tags)
    read_tags = filter_permission_tags(statement_tags, :read)

    if read_tags.empty? # no read permission tags, good to go
      return true
    elsif current_user.nil? # no user logged in, can't access closed statements
      return false
    elsif current_user.has_role? :editor # editor can read everything
      return true
    else
      # Calculate for the remaining users
      decision_making_tags = current_user.decision_making_tags
      read_tags.each do |tag|
        return true if decision_making_tags.include? tag  # User has one of the **tags
      end

      #User has none of the **tags -> no read permission
      return false
    end
  end

  #
  # Returns *tags or **tags according to the given access level.
  #
  # access_level: :read, :write or :read_write
  #
  def filter_permission_tags(tags, access_level)
    tags.map{|t| t.strip}.uniq.select{|t| t.start_with?(access_level == :read ? '**' : '*')}
  end

  #
  # Checks if the user has write permission on the current statement node (based on *tags).
  #
  def check_write_permission
    statement_node = @statement_node || parent
    return statement_node.nil? ? true : has_write_permission?(statement_node.root.topic_tags)
  end

  #
  # Checks whether the user is allowed to write a statement with the given tags.
  #
  def has_write_permission?(statement_tags)
    write_tags = filter_permission_tags(statement_tags, :write)

    if write_tags.empty? # no write permission tags, good to go
      return true
    elsif current_user.nil? # no user logged in, can't write protected statements
      return false
    else
      # Calculate for the remaining users
      decision_making_tags = current_user.decision_making_tags
      write_tags.each do |tag|
        return true if decision_making_tags.include? tag   # User has one of the *tags
      end

      # User has none of the *tags -> no write permission
      set_info('discuss.statements.read_only_permission')
      respond_to do |format|
        format.html { flash_info and redirect_to request.referer }
        format.js do
          render_with_info
        end
      end
      return false
    end
  end


  ##########
  # SEARCH #
  ##########

  #
  # Calls the statement node sql query for questions.
  # opts attributes:
  #
  # search_term (String : optional) : text snippet to look for in the statements
  #
  # for more info about attributes, please check the StatementNode.search_statement_nodes documentation
  #
  def search_statement_nodes(opts = {})
    opts[:language_ids] ||= filter_languages
    StatementNode.search_statement_nodes(opts.merge({:user => current_user,
                                                     :show_unpublished => current_user && current_user.has_role?(:editor)}))
  end

  #
  # Gets all the statement documents belonging to a group of statements, and orders them per language ids.
  # opts attributes:
  #
  # statement_ids (Array[Integer]) : ids from statements which documents we should look through
  # for more info about attributes, please check the StatementDocument.search_statement_documents documentation
  #
  def search_statement_documents(opts={})
    opts[:language_ids] ||= @language_preference_list
    opts[:user] = current_user
    statement_documents = StatementDocument.current_documents.by_statements(opts[:statement_ids], opts[:more]).
                                           by_languages(opts[:language_ids], (current_user.nil? or current_user.spoken_languages.empty?)).
                                           sort! {|a, b|
      a_index = opts[:language_ids].index(a.language_id)
      b_index = opts[:language_ids].index(b.language_id)
       (a_index and b_index) ? a_index <=> b_index : 0
    }
    statement_documents.each_with_object({}) do |sd, documents_hash|
      documents_hash[sd.statement_id] = sd unless documents_hash.has_key?(sd.statement_id)
    end
  end


  #
  # Loads the discuss alternative node and document from a statement node.
  #
  # statement_node(StatementNode) : the statement node
  #
  # Loads instance variables:
  # @discuss_alternatives_questions(Hash) : key   : statement node dom id
  #                                         value : DiscussAlternativesQuestion
  # @discuss_alternatives_documents(Hash) : key   : statement_id: statement_id from a daq
  #                                         value : StatementDocument: document in the preferred language
  #
  def load_discuss_alternatives_question(statement_node)
    return if statement_node.new_record? or !@node_environment.alternative_mode?(statement_node)
    @discuss_alternatives_questions ||= {}
    @discuss_alternatives_documents ||= {}

    # don't proceed if there is no discuss alternative yet
    daq = statement_node.discuss_alternatives_question
    return if daq.nil?
    
    
    class_name = statement_node.target_statement.u_class_name
    @discuss_alternatives_questions["#{class_name}_#{statement_node.target_id}"] ||= daq 
    @discuss_alternatives_documents[daq.statement_id] ||= daq.document_in_preferred_language(@language_preference_list)
  end

  ############################
  # SESSION HANDLING HELPERS #
  ############################

  #
  # Loads information necessary to build a breadcrumb for the new Follow Up Statement
  #
  # Loads instance variables:
  # @previous_node(StatementNode) : the parent of the new statement
  # @previous_type(String) : type of breadcrumb
  #
  def load_origin_statement
    @previous_node = @statement_node.parent_node
    @previous_type = case @statement_node_type.name
      when "FollowUpQuestion" then "fq"
      when "DiscussAlternativesQuestion" then "dq"
    end
  end


  #
  # Loads the ancestors of the current statement node, in order to display the correct context.
  # On the process, loads its siblings (check load_siblings, load_roots_to_session and load_children_for_parent documentation)
  #
  # teaser(Boolean) : if true, @statement_node is the PARENT node of the teaser.
  #
  # Loads instance variables:
  # @ancestors(Array[StatementNode]) : ancestors of the current statement node
  # @ancestor_documents(Hash) : key   : statement id (Integer)
  #                             value : document (StatementDocument)
  #                             documents belonging to the loaded ancestors
  #
  def load_ancestors(teaser = false)

    if @statement_node
      @ancestors = @node_environment.ancestors
      @ancestor_documents = {}
      @ancestors.each {|a| 
        load_siblings(a)
        load_discuss_alternatives_question(a) 
      }

      load_siblings(@statement_node) # if teaser: @statement_node is the teaser's parent, otherwise the node on the bottom-most level
      load_discuss_alternatives_question(@statement_node)
      if teaser

        # if teaser: @statement_node is the teaser's parent, therefore, an ancestor
        # if stack ids exists, that means the @statement node is already in ancestors
        @ancestors << @statement_node if !@node_environment.alternative_mode?(@node_environment.level) and !@ancestors.map(&:id).include?(@statement_node.id)
        load_children_for_parent(@statement_node, @type)
      end

      @ancestors.each do |a|
        l_ids = (@language_preference_list + [a.original_language.id]).uniq
        @ancestor_documents[a.statement_id] = a.document_in_preferred_language(l_ids)
      end
    else
      if teaser
        load_roots_to_session
      else
        @ancestors = []
      end
    end
  end

  #
  # Loads the children ids array formatted for session from a certain type of a certain statement node
  #
  # statement_node(StatementNode) : the parent node
  # type(String)                  : the type of children we want to get
  #
  # Loads instance variables:
  # @siblings(Hash) : key   : statement node dom id ; ":type_:id" or "add_:type" for teasers (String)
  #                   value : Array[Integer] : Array of statement ids with teaser path as last element
  #
  def load_children_for_parent(statement_node, type)
    @siblings ||= {}
    class_name = type.classify
    siblings = statement_node.children_to_session :language_ids => @language_preference_list,
                                                    :type => class_name, :user => current_user
    @siblings["add_#{type}"] = siblings
  end

  #
  # Loads siblings of a statement node.
  #
  # statement_node(StatementNode) : the statement node
  #
  # Loads instance variables:
  # @siblings(Hash) : key   : statement node dom id ; ":type_:id" or "add_:type" for teasers (String)
  #                   value : Array[Integer] : Array of statement ids with teaser path as last element
  #
  def load_siblings(statement_node)
    return if statement_node.new_record?
    @siblings ||= {}
    class_name = statement_node.target_statement.u_class_name


    # if has parent then load siblings
    if statement_node.parent_id
      prev = @node_environment.statement_node_above(statement_node)
      hub = statement_node.id if @node_environment.alternative_mode?(statement_node)
      siblings = statement_node.siblings_to_session :language_ids => @language_preference_list,
                                                    :user => current_user,
                                                    :prev => prev,
                                                    :hub => hub
    else #else, it's a root node
      siblings = roots_to_session(statement_node)
    end
    @siblings["#{class_name}_#{statement_node.target_id}"] = siblings
  end
  

  #
  # Loads Add Question Teaser siblings (Only for HTTP and add question teaser).
  #
  # Loads instance variables:
  # @siblings(Hash) : key   : statement node dom id ; ":type_:id" or "add_:type" for teasers (String)
  #                   value : Array[Integer] : Array of statement ids with teaser path as last element
  #
  def load_roots_to_session
    @siblings ||= {}
    @siblings["add_question"] = roots_to_session
  end

  #
  # Gets the root ids that need to be loaded to the session.
  #
  # statement_node(StatementNode : optional) : statement node which is currently shown
  #
  def roots_to_session(statement_node=nil)
    load_roots :node => statement_node, :per_page => -1, :for_session => true
  end


  #
  # Loads The Roots for current Top Statement (Question, Follow Up Question, ...)
  # opts attributes:
  #
  # node (StatementNode : optional) : statement node which is currently shown
  # page (Integer : optional) : pagination parameter (default = 1)
  # per_page (Integer : optional) : pagination parameter (default = QUESTIONS_PER_PAGE)
  #
  # Loads instance variables (if not for session):
  # @children(Hash) : key   : class name (String)
  #                   value : an array of statement nodes (Array) or an URL (string)
  # @children_documents(Hash) : key   : statement_id (Integer)
  #                             value : document (StatementDocument)
  #
  def load_roots(opts)
    opts[:page] ||= 1
    opts[:per_page] ||= QUESTIONS_PER_PAGE
    opts[:for_session] ||= false
    if @node_environment.origin? #statement node is a question
      roots = case @node_environment.origin.key

        # get question siblings depending from the request's origin (key)
        # discuss search with no search results
        when 'ds' then
          sn = search_statement_nodes(:param => opts[:for_session] ? 'root_id' : nil, :node => opts[:node]).
                 paginate(:page => 1, :per_page => @node_environment.origin.page * QUESTIONS_PER_PAGE)
          opts[:for_session] ? sn.map(&:root_id) + ["/add/question"] : sn

        # discuss search with search results
        when 'sr'then
          sn = search_statement_nodes(:search_term => @node_environment.origin.terms,
                                      :param => opts[:for_session] ? 'root_id' : nil,
                                      :node => opts[:node]).paginate(:page => 1, :per_page => @node_environment.origin.page * QUESTIONS_PER_PAGE)
          opts[:for_session] ? sn.map(&:root_id) + ["/add/question"] : sn

        # my discussions
        when 'mi' then
          sn = Question.by_creator(current_user).by_creation
          opts[:for_session] ? sn.only_id.map(&:id) + ["/add/question"] : sn

        # jumped from
        when 'jp' then
          nodes = opts[:node].nil? ? [] : [opts[:node]]
          opts[:for_session] ? nodes.map(&:id) + ["/add/question"] : nodes
          
        # follow up questions from a statement
        when 'fq' then
          @previous_node = StatementNode.find(@node_environment.origin.value)
          @previous_type = "FollowUpQuestion"
          sn = @previous_node.child_statements :language_ids => filter_languages_for_children,
                                                               :type => @previous_type,
                                                               :user => current_user,
                                                               :for_session => opts[:for_session]
          opts[:for_session] ? sn : sn.map(&:target_statement)
      end
    else
      # no origin (direct link)
      roots = opts[:node].nil? ? [] : [opts[:node]]
      roots = roots.map(&:id) + ["/add/question"] if opts[:for_session]
    end

    if !opts[:for_session] # for descendants, must load statement documents and fill the necessary attributes for rendering
      per_page = opts[:per_page].to_i == -1 ? roots.length : opts[:per_page].to_i
      per_page = 1 if per_page == 0 # in case roots is an empty array
      @children = {}
      type = opts[:node].nil? ? @type : opts[:node].class.name
      @children[type.to_sym] = roots.paginate :page => opts[:page].to_i, :per_page => per_page

      @children_documents = search_statement_documents :statement_ids => @children[type.to_sym].flatten.map(&:statement_id)
    end
    roots
  end

  #########################
  # RENDER HELPER METHODS #
  #########################

  #
  # Loads the level which the statement (or teaser) will be rendered in
  #
  # teaser (boolean : optional) : whether what we are rendering now is a teaser or a statement
  #
  # Loads instance variables:
  # @level(Integer)
  #
  def load_statement_level(teaser = false)
    # if it is a teaser, calculate the level of the current parent and add 1 (unless it's a question or follow up teaser)
    @statement_node.level ||= teaser ?
                             ((@statement_node.nil? or @type.classify.constantize.is_top_statement?) ?
                               0 : @statement_node.level + 1) :
                             @statement_node.level
  end

  ####################
  # RESPONSE RENDERS #
  ####################

    %w(info error).each do |type|
    class_eval %(
        def render_statement_with_#{type}(opts={}, &block)
          respond_to do |format|
            format.html do
              flash_#{type}
              opts[:template] ? (render :template => opts[:template]) : show
            end
            format.js { render_with_#{type} &block }
          end
        end
      )
  end

  def show_statement(errors = false)
    respond_to do |format|
      format.html {
        errors ? flash_error : flash_info
        redirect_to_statement
      }
      format.js {
        block_given? ? yield : (errors ? render_with_error : show)
      }
    end
  end

  def render_template(template, teaser = false)
    respond_to do |format|
      format.html {
        load_ancestors(teaser)
        load_breadcrumbs
        render :template => template
      }
      format.js {
        load_ancestors(teaser) if !params[:sids].blank? or (@node_environment.new_level? and (@statement_node.nil? or @statement_node.level == 0))
        load_breadcrumbs if @node_environment.bids?
        load_statement_level(teaser)
        render :template => template
      }
    end
  end
  
  def load_statement_node_errors
    set_error(@statement_node, :only => ["statement.statement_documents.title", 
                                         "statement.statement_documents.text"])
    if @statement_node.class.has_embeddable_data?
      set_error(@statement_node.statement, :only => [:info_type_id, :external_url])
      @statement_node.statement_datas.each{|s|set_error(s)}
    end
  end

  ########
  # MISC #
  ########

  #
  # Sets the info to displayed along with the response.
  # The action name is automagically incorporated into the I18n key.
  #
  def set_statement_info(object)
    code = object.kind_of?(String) ? object : "discuss.messages.#{object.action.code}"
    set_info code, :type => I18n.t("discuss.statements.types.#{@statement_node.u_class_name}")
  end

  #
  # Loads search terms from the search as tags for the statement node.
  #
  def load_search_terms_as_tags(pair)
    return if pair.nil? or !pair.sr?
    default_tags = pair.terms
    default_tags[/[\s]+/] = ',' if default_tags[/[\s]+/]
    default_tags = default_tags.split(',').compact
    default_tags.each{|t| @statement_node.topic_tags << t }
    @tags ||= @statement_node.topic_tags if @statement_node.taggable?
  end

  #
  # Shows "being edited" info message and refreshes the statement.
  #
  def being_edited
    respond_to do |format|
      set_error('discuss.statements.staled_modification')
      format.html { flash_error and redirect_to_statement }
      format.js { show }
    end
  end

  ###########
  # LOGGERS #
  ###########

  # Logs the exception and redirects to the statement.
  def log_error_statement(e, message)
    log_message_error(e, message) do
      flash_error and redirect_to_statement
    end
  end

  # Logs the exception and redirects to home.
  def log_error_home(e, message)
    log_message_error(e, message) do
      flash_error and redirect_to_app_home
    end
  end

end
