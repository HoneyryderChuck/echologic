module StatementsHelper

  include PublishableModuleHelper
  include EchoableModuleHelper
  include IncorporationModuleHelper
  include TranslationModuleHelper


  ##################
  # RENDER HELPERS #
  ##################

  #
  # Renders the embed statement panel to copy the embed code for the currently displayed statement.
  #
  def render_embed_panel(url, mode)
    embedded_code = %Q{<iframe src="#{url}" width="100%" height="4000px" frameborder="0"></iframe>}
    content_tag(:div,
                :class => 'embed_panel popup_panel',
                :style => "display:none") do
      concat( 
        content_tag(:div, I18n.t("discuss.statements.embed_#{mode}_title"), :class => 'panel_header') +
        content_tag(:div, I18n.t("discuss.statements.embed_#{mode}_hint")) + 
        content_tag(:div, h(embedded_code), :class => 'embed_code')
      )
    end
  end


  #
  # Renders the Copy URL panel to copy the statement URL into the clipboard.
  #
  def render_copy_url_panel(url)
    content_tag(:div, :class => 'copy_url_panel popup_panel',
                      :style => "display: none") do
      concat(
        content_tag(:div, I18n.t("discuss.statements.copy_url_title"), :class => 'panel_header') + 
        content_tag(:div, I18n.t('discuss.statements.copy_url_hint'), :class => '') +
        content_tag(:div, h(url), :class => 'statement_url')
      )
    end
  end


  #########
  # Links #
  #########

  #
  # Creates a link to create a new child statement of a given type for the current statement
  # (appears INSIDE of the children statements panel).
  #
  def create_new_child_statement_link(statement_node, child_type, opts={})
    url = opts.delete(:url) if opts[:url]
    css = opts.delete(:css) if opts[:css]
    label_type = opts.delete(:label_type) || child_type
    link_to(I18n.t("discuss.statements.create_#{label_type}_link"),
            url ? url : new_statement_node_url(statement_node.nil? ? nil : statement_node.target_id,child_type, opts),
            :class => "#{css} add_new_button text_button create_#{label_type}_button ttLink no_border",
            :title => I18n.t("discuss.tooltips.create_#{label_type}"))
  end

  def create_new_question_link(opts={})
    type = 'question'
    parent = nil
    if @node_environment.origin.present?
      parent = case @node_environment.origin.key
        when 'ds', 'sr', 'mi' then nil
        when 'fq' then type = 'follow_up_question'
                       @node_environment.origin.value
      end
    end
    url = parent.nil? ? new_question_url(:bids => @node_environment.origin.to_s, :origin => @node_environment.origin.to_s) : new_statement_node_url(parent, type)
    create_new_child_statement_link(parent, type, opts.merge({:url => url}))
  end


  def add_create_new_statement_button(statement_node, type, opts={})
    style = opts.delete(:style)
    if statement_node.nil? # only for siblings; there ain't no child question creation possibility; hence, no new_level param is given
       content_tag :li, create_new_question_link(opts), :style => style
    else
       content_tag :li, create_new_child_statement_link(statement_node, type, opts), :style => style
    end
  end


  #
  # Creates a link to add a new sibling for the given statement (appears in the SIDEBAR).
  #
  def add_new_sibling_button(statement_node)
    content = ''
    statement_node.class.sub_types.map.each do |sub_type|
      sub_type = sub_type.to_s.underscore
      content << content_tag(:a, :href => new_statement_node_url(@node_environment.previous_statement_node(statement_node) || statement_node.parent_node, sub_type),
                             :class => "create_#{sub_type}_button_32 resource_link new_statement ttLink no_border",
                             :title => I18n.t("discuss.tooltips.create_#{sub_type}")) do
        statement_icon_title(I18n.t("discuss.statements.types.#{sub_type}"))
      end
    end
    content
  end


  #
  # Returns a link to create a new child statement from a given type for the given statement (appears in the SIDEBAR).
  #
  def add_new_child_link(statement_node, type, opts={})
    opts[:nl] = true
    content = ''
    content << content_tag(:a, :href => new_statement_node_url(statement_node, type, opts),
                           :class => "create_#{type}_button_32 resource_link new_statement ttLink no_border",
                           :title => I18n.t("discuss.tooltips.create_#{type}")) do
      statement_icon_title(I18n.t("discuss.statements.types.#{type}"))
    end
    content
  end

  #
  # Creates a link to edit the current document.
  #
  def edit_statement_node_link(statement_node, statement_document)
    if current_user and current_user.may_edit?(statement_node)
      link_to(I18n.t('application.general.edit'),
              edit_statement_node_url(statement_node,
                                      :current_document_id => statement_document.id,
                                      :cs => @node_environment.current_stack.to_s),
              :class => 'ajax header_button text_button edit_text_button')
    else
      ''
    end
  end

  #
  # Creates a link to show the authors of the current node.
  #
  def authors_statement_node_link(statement_node)
    link_to(I18n.t('application.general.authors'),
            authors_statement_node_url(statement_node),
            :class => 'expandable header_button text_button authors_text_button')
  end

  #
  # Render the list of authors.
  #
  def render_authors(statement_node, user, authors)
    content_tag(:ul, :class => 'authors_list') do
      concat(
        render(:partial => 'statements/author', :collection => authors) +
        ((statement_node.draftable? and !authors.include?(user)) ? author_teaser(statement_node, user) : '')
      )
    end
  end

  #
  # Creates a teaser for authors with author styling.
  #
  def author_teaser(statement_node, user)
    content_tag :li, :class => 'author teaser' do
      concat(
        image_tag(user.avatar.url(:small), :alt => '') +
        content_tag(:span, I18n.t('users.authors.teaser.title'), :class => 'name') +
        create_new_child_statement_link(statement_node, 'improvement', :nl => true, :css => "new_statement")
      )
    end
  end

  #
  # Creates a link to delete the current statement.
  #
  def delete_statement_node_link(statement_node)
    link_to I18n.t('discuss.statements.delete_link'),
            statement_node_url(statement_node),
            :class => 'admin_action',
            :method => :delete,
            :confirm => I18n.t('discuss.statements.delete_confirmation')
  end


  #
  # Returns the block heading for the children of the current statement node.
  #
  def children_heading_title(type, count, opts={})
    content_tag :a, :href => opts[:path],
                    :type => type.pluralize,
                    :class => "#{type.pluralize} child_header #{'selected' if opts[:selected]}" do
      content_tag :div, :class => "header_content" do
        concat(
          content_tag(:span, I18n.t("discuss.statements.headings.#{type}"), :class => 'type') +
          content_tag(:span, " (#{count})", :class => 'count')
        )
      end
    end
  end

  #
  # Returns the block heading for the siblings of the current statement node.
  #
  def sibling_box_title(type)
    content_tag :span, I18n.t("discuss.statements.headings.#{@hub_type || type}", :type => type), :class => 'label'
  end

  #
  # Creates the cancel button in the new statement form (right link will be handled in jquery).
  #
  def cancel_new_statement_node
    link_to I18n.t('application.general.cancel'),
            :back,
            :class => 'cancel text_button cancel_text_button'
  end

  #
  # Creates the cancel button in the edit statement form.
  #
  def cancel_edit_statement_node(statement_node, locked_at)
    link_to I18n.t('application.general.cancel'),
            cancel_statement_node_url(statement_node,
                                      :locked_at => locked_at.to_s,
                                      :cs => @node_environment.current_stack.to_s),
           :class => "text_button cancel_text_button ajax"
  end

  def title_hint_text(statement_node)
    I18n.t("discuss.statements.title_hint.#{node_type(statement_node)}")
  end

  def summary_hint_text(statement_node)
    hint = ""
    hint << I18n.t("discuss.statements.text_hint.alternative_prefix") if @node_environment.hub?
    hint << I18n.t("discuss.statements.text_hint.#{node_type(statement_node)}")
    hint 
  end

  ##############
  # Sugar & UI #
  ##############

  def node_type(statement_node)
    @statement_type ||= {}
    @statement_type[statement_node.level] ||= statement_node.new_record? ? @statement_node_type.name.underscore :
                                                                           dom_class(statement_node.target_statement)
  end
  
  def has_embeddable_data?(statement_node)
     @statement_node_type ? @statement_node_type.has_embeddable_data? : statement_node.class.has_embeddable_data?
  end
  
  def is_publishable?(statement_node)
    @statement_node_type ? @statement_node_type.publishable? : statement_node.publishable?
  end
  

  # 
  # returns the dom id structure of the statement representing the parent of the statement node in the given context
  #
  def parent_statement_dom_id(statement_node)
    @node_environment.alternative_mode?(statement_node) ? 
    "alternative_#{statement_node.target_id}" : 
    (statement_node.parent_node ? dom_id(statement_node.parent_node) : @node_environment.origin.to_s) 
  end
  
  def statement_element_attributes(statement_node)
    klasses = ["statement"]
    klasses << [statement_node.class.name_for_siblings, node_type(statement_node)].uniq.join(' ')
    klasses << 'echoable' if statement_node.echoable?
    klasses << 'alternative' if @node_environment.alternative_mode?(statement_node)
    {
      :id => dom_id(statement_node), 
      :class => klasses.join(" "),
      :'data-siblings' => (@siblings.to_session(dom_id(statement_node)).to_json unless @siblings.blank?),
      :'dom-parent' => parent_statement_dom_id(statement_node)
   }
  end
 
  def new_statement_element_attributes(klass, statement_node)
    klasses = %w(ajax_form new wide_form statement)
    klasses << node_type(statement_node)
    klasses << 'alternative' if @node_environment.hub?
    klasses << 'taggable' if klass.taggable?
    klasses << 'echoable' if klass.echoable?
    klasses << 'embeddable no_type' if klass.has_embeddable_data? 
    {
      :class => klasses.join(" "),
      :'dom-parent' => statement_node.parent_node ?
                      "#{dom_class(statement_node.parent_node)}_#{statement_node.parent_node.target_id}" :
                      @node_environment.origin.to_s
    }
  end
  
  def edit_statement_element_attributes(statement_node)
    klasses = %w(ajax_form edit wide_form statement)
    klasses << 'taggable' if statement_node.taggable?
    klasses << 'echoable' if statement_node.echoable?
    klasses << "embeddable #{statement_node.info_type.code}" if statement_node.class.has_embeddable_data? 
    {
      :class => klasses.join(" "),
      :'data-siblings' => @siblings ? @siblings.to_session(dom_id(statement_node)).to_json : ''
    }
  end
  
  def translate_statement_element_attributes(statement_node)
    klasses = %w(ajax_form wide_form translation statement)
    klasses << statement_node.info_type.code if statement_node.class.has_embeddable_data?
    klasses << 'taggable' if statement_node.taggable?
    klasses << 'echoable' if statement_node.echoable?
    { :class => klasses.join(" ") }
  end
  
  def add_statement_element_attributes(klass)
    klasses = %w(statement add_teaser echoable)
    klasses << type
    klasses << 'alternative' if @node_environment.alternative_mode?(@node_environment.level)
    {
     :id => "add_#{@type}",
     :class => klasses.join(" "),
     :'data-siblings' => (@siblings.to_session("add_#{@type}").to_json if @siblings)
    }
  end


  #
  # Loads the right add statement image.
  #
  def statement_form_illustration(statement_node)
    image_tag("page/discuss/add_#{node_type(statement_node)}_big.png",
              :class => 'statement_form_illustration')
  end

  #
  # Returns the right icon for a statement_node, determined from statement_node class and given size.
  #
  def statement_node_icon(statement_node, size = :medium)
    # remove me to have different sizes again
    image_tag("page/discuss/#{node_type(statement_node)}_#{size.to_s}.png")
  end

  #
  # Returns the context menu link for this statement_node.
  #
  def statement_node_context_link(statement_node, title, action = 'read', opts={})
    css = String(opts.delete(:css))
    css << " #{statement_node.info_type.code}_link" if statement_node.class.has_embeddable_data?
    link_to(statement_node_url(statement_node, opts),
            :class => "#{css} no_border statement_link #{node_type(statement_node)}_link ttLink",
            :title => I18n.t("discuss.tooltips.#{action}_#{node_type(statement_node)}")) do
      statement_icon_title(title)
    end
  end

  #
  # Render the hint on the new statement forms for users with no spoken language defined.
  #
  def define_languages_hint
    content_tag :p, I18n.t('discuss.statements.statement_language_hint', :url => my_profile_url),
                :class => 'ttLink no_border',
                :title => I18n.t('discuss.statements.statement_language_hint_tooltip')
  end

  #
  # Render the hint on the new draftable statement forms to warn about drafting language on collective text creation.
  #
  def drafting_language_hint
    content_tag :p, I18n.t('discuss.statements.drafting_language_hint')
  end

  def top_statement_hint
    content_tag :p, I18n.t("discuss.statements.fuq_formulation_hint")
  end

  #
  # Render the hint on the edit statement forms to warn about the time the users have to edit it.
  #
  def edit_period_hint
    content_tag(:li, :class => 'hint') do
      content_tag :p, I18n.t('discuss.statements.edit_period_hint', :minutes => 60)
    end
  end


  ##############
  # Navigation #
  ##############

  # gets the path that the siblings button loads
  def siblings_path(statement_node, klass = node_type(statement_node))
    if @node_environment.alternative_mode?(statement_node)
      sib = statement_node
      alternative_type = klass.classify.constantize.name_for_siblings
      name = "alternative"
    end
    name ||= klass.classify.constantize.name_for_siblings
    
    
    if statement_node.nil? or statement_node.u_class_name != klass # ADD TEASERS
      if statement_node.nil?
        question_descendants_url(:origin => @node_environment.origin.to_s)
      else
        parent = (@node_environment.current_stack? ? @node_environment.previous_id(statement_node) : statement_node) # TODO: CHECK IF THIS WILL NOT FAIL BIG TIME
        descendants_statement_node_url(parent, name, :alternative_type => alternative_type)
      end
    else  # STATEMENT NODES

      if statement_node.parent_id.nil?
        question_descendants_url(:origin => @node_environment.origin.to_s, :current_node => statement_node)
      else
        prev = sib ||
               (@node_environment.current_stack? ?
               @node_environment.previous_statement_node(statement_node) :
               statement_node.parent_node)

        descendants_statement_node_url(prev,
                                       name,
                                       :current_node => statement_node,
                                       :alternative_type => alternative_type,
                                       :hub => ("al#{statement_node.target_id}" if @node_environment.alternative_mode?(statement_node)))
      end
    end
  end
  
  # gets the right label for the siblings button
  def siblings_label(statement_node, klass = node_type(statement_node))
    if @node_environment.alternative_mode?(statement_node)
      alternative_type = klass.classify.constantize.name_for_siblings
      name = "alternative"
    end
    name ||= klass.classify.constantize.name_for_siblings
    
    I18n.t("discuss.statements.sibling_labels.#{@node_environment.alternative_mode?(statement_node) ? alternative_type : name}")
  end
  
  # get tooltip for the siblings button
  def siblings_tooltip(statement_node, klass = node_type(statement_node))
    I18n.t("discuss.tooltips.siblings.#{@node_environment.alternative_mode?(statement_node) ? 'alternative' : klass.classify.constantize.name_for_siblings}")
  end



  #
  # Renders the correct prev/next image buttons.
  #
  def statement_tag(direction, class_identifier, disabled=false)
    if !disabled
      content_tag(:span, '&nbsp;',
                  :class => "#{direction}_stmt ttLink no_border",
                  :title => I18n.t("discuss.tooltips.#{direction}_#{class_identifier}"))
    else
      content_tag(:span, '&nbsp;',
                  :class => "#{direction}_stmt disabled")
    end
  end

  #
  # Inserts a button that links to the previous statement_node.  #
  # IMP NOTE: siblings always include the teaser at the end, so always be careful when handling it
  #
  def statement_button(statement_node, title, type, options={})
    options[:class] ||= ''
    teaser = options[:class].include? 'add'
    url_opts = {:origin => @node_environment.origin.to_s, :bids => @node_environment.bids.to_s}
    # if prev/next for teaser
    unless @siblings.nil?
      if teaser
        if (siblings = @siblings.to_session("add_#{@type}"))
          element_index = siblings.index { |s| s =~ /#{@type}/ }
        end
      else # if prev/next for statement
        if (siblings = @siblings.to_session(dom_id(statement_node)))
          element_index = siblings.index(statement_node.id)
        end
      end
      unless siblings.nil?
        element_index = 0 if element_index.nil?
        index = element_index
        if options[:rel].eql? :prev
          index = element_index - 1
        elsif options[:rel].eql? :next
          index = element_index + 1
        end
        index = index < 0 ? (siblings.length - 1) : (index >= siblings.length ? 0 : index )

        url = !(siblings[index].to_s =~ /add/).nil? ? add_teaser_statement_node_path(statement_node,url_opts) :
                                                      statement_node_url(siblings[index], url_opts)
      end
    else
      url = add_teaser_statement_node_path(statement_node)
    end
    options['data-id'] = teaser ? "#{statement_node.nil? ? '' : "#{statement_node.id}_"}add_#{type}" : statement_node.id
    return link_to(title, url, options)
  end

  def add_teaser_statement_node_path(statement_node, opts={})
    if statement_node.nil? or statement_node.level == 0
      add_question_teaser_url(opts)
    else
      add_teaser_url(statement_node.parent_node, opts.merge(:type => dom_class(statement_node)))
    end
  end


  #
  # Loads the link to a given statement, placed in the child panel section.
  #
  def link_to_child(title, statement_node,opts={})
    opts[:type] ||= dom_class(statement_node) #TODO: This forced op must be deleted when alternatives navigation/breadcrumb are available
    # BIDS
    bids = @node_environment.bids.to_s
    if opts[:nl]
      bid = "#{Breadcrumb.generate_key(opts[:type])}#{@statement_node.target_id}"
      bids = @node_environment.add_bid(bid).to_s
    end

    # AL
    level = @node_environment.stack_level(statement_node)
    al = @node_environment.add_alternative_mode(level).to_s if opts[:alternative_link]

    link_to(statement_icon_title(title),
            statement_node_url(statement_node.target_id,
                               :bids => bids.to_s,
                               :origin => @node_environment.origin.to_s,
                               :nl => opts[:nl],
                               :al => al),
           :class => "statement_link #{opts[:type]}_link #{opts[:css]}") +
    render(:partial => "statements/supporters", :locals => {:statement_node => statement_node})
  end


  #
  # Creates a statement link with icon and title.
  #
  def statement_icon_title(title)
    content_tag(:span, '&nbsp;', :class => 'icon') +
    content_tag(:span, h(title), :class => 'title')
  end


  def new_statement_image(statement_node)
    content_tag :div, :class => "image_container editable" do
      concat(
        image_tag(statement_node.image.url(:medium), :class => 'image') +
        link_to(I18n.t('users.profile.picture.upload_button'),
                new_statement_image_url(node_type(statement_node)),
                :class => 'ajax upload_link button button_150')
      )
    end
  end

  #
  # Draws the statement image container.
  #
  def statement_image(statement_node)
    val = ""
    editable = (current_user and current_user.may_edit?(statement_node))
    if statement_node.image.exists? or editable
      val << image_tag(statement_node.image.url(:medium), :class => 'image')
      if editable
        val << link_to(I18n.t('users.profile.picture.upload_button'),
                       edit_statement_image_url(statement_node.statement_image, statement_node),
                       :class => 'ajax upload_link button button_150')
      end
    end
    content_tag :div, val, :class => "image_container #{editable ? 'editable' : ''}" if !val.blank?
  end

  #
  # Renders the "more" link when the statement is loaded.
  #
  def more_children(statement_node,opts={})
    opts[:page] ||= 0
    link_to I18n.t("application.general.more"),
            more_statement_node_url(statement_node, :page => opts[:page].to_i+1,
                                                    :type => opts[:type],
                                                    :bids => @node_environment.bids.to_s,
                                                    :origin => @node_environment.origin.to_s,
                                                    :hub => opts[:hub],
                                                    :nl => opts[:new_level]),
            :class => 'more_children'
  end


  def render_alternative_types(statement_node, statement_types, selected=statement_types.first)
    if statement_types.length > 1
      render_statement_types_radio_buttons(statement_types, selected)
    else
      hidden_field_tag :type, node_type(statement_node)
    end
  end

  def render_statement_types_radio_buttons(statement_types, selected=statement_types.first)
   content = ""
   statement_types.each do |statement_type|

     content << radio_button_tag(:type, statement_type, statement_type.eql?(selected), :class => "statement_type") +
                label_tag(statement_type, I18n.t("discuss.statements.types.#{statement_type}"), :class => "statement_type_label")
   end
   content
  end

  ################
  # ALTERNATIVES #
  ################

  def close_alternative_mode_button(statement_node)
    link_to '', statement_node_url(statement_node, 
                                   :bids => @node_environment.pop_bid.to_s, 
                                   :origin => @node_environment.origin.to_s, 
                                   :al => @node_environment.remove_alternative_mode(@node_environment.level).to_s),
            :class => "alternative_close ttLink no_border",
            :title => I18n.t("discuss.tooltips.close_alternative_mode")
  end

  #
  # Returns the block heading for the alternative tag on the alternative header
  #
  def alternative_header_box_title
    content_tag :span, "#{I18n.t("discuss.statements.headings.alternative")}", :class => 'label'
  end

  def create_discuss_alternatives_question_link(statement_node)
    create_new_child_statement_link(statement_node, "discuss_alternatives_question", :css => "new_statement", :nl => true, :origin => @node_environment.origin.to_s, :bids => @node_environment.bids.to_s)
  end
  
  #
  # This class does the heavy lifting of actually building the pagination
  # links. It is used by the <tt>will_paginate</tt> helper internally.
  #
  class MoreRenderer < WillPaginate::LinkRenderer
    def to_html
      html = page_link_or_span(@collection.next_page, 'disabled more_children', @options[:next_label])
      html = html.html_safe if html.respond_to? :html_safe
      @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
    end
  end

end

