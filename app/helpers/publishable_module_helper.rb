require 'sanitize'

module PublishableModuleHelper

  #
  # get the text that shows up on the top left corner of discuss search results
  #
  def questions_count_text(count, search_terms = nil)
    text = count_text("discuss", count)
    text << " #{I18n.t('discuss.for', :value => search_terms)}" if !search_terms.blank?
    text
  end


  #
  # create question button above the discuss search results and on the left corner of my questions
  #
  def create_question_link_for(origin=@origin)
    link_to(new_question_url(:origin => origin, :bids => origin),
                             :id => 'create_question_link',
                             :class => 'add_new_button big_action_button') do
      link_content = ''
      link_content << content_tag(:span, '',
                                  :class => "add_new_question_icon ttLink no_border",
                                  :title => I18n.t("discuss.tooltips.create_question"))
      link_content <<  content_tag(:span, I18n.t("discuss.my_questions.add"),
                                   :class => 'label')
      link_content
    end
  end

  #
  # create question button on the search results area when no results where found
  #
  def create_first_question_link_for(search_terms='')
    origin = "sr#{search_terms}"
    link_to(new_question_url(:origin => origin, :bids => origin),
            :id => 'create_question_teaser_link',
            :class => 'no_results create_first_question_button') do
      content_tag(:span, I18n.t('discuss.search.add'))
    end
  end


  #
  # question link for the discuss search results
  #
  def image_link_to_question(question, origin=@origin)
    link_to statement_node_url(question, :origin => origin, :bids => origin),
            :class => "avatar_holder" do
      image_tag question.image.url(:medium), :alt => ''
    end
  end


  #
  # Creates a button link to create a new question (SIDEBAR).
  #
  def add_new_question_button
    content_tag(:a, :href => new_question_url(:origin => @node_environment.origin.to_s, :bids => @node_environment.origin.to_s),
                :class => "create_question_button_32 resource_link ajax ttLink no_border",
                :title => I18n.t("discuss.tooltips.create_question")) do
      statement_icon_title(I18n.t("discuss.statements.types.question"))
    end
  end

  #
  # Creates a featured topic link in the discuss search action panel.
  #
  def featured_topic_link(topic, search_terms)
    link_to(discuss_search_url(:search_terms => search_terms),
            :class => 'featured_topic') do
      content = ''
      content << image_tag("page/discuss/topics/#{topic}.png",
                           :class => "featured_topic_picture",
                           :alt => '')
      content << content_tag(:span, I18n.t("discuss.topics.#{topic}.name"),
                             :class => 'featured_topic_label')
      content
    end
  end


  #
  # publish button that appears on the right top corner of the statement
  #
  def publish_statement_node_link(statement_node, statement_document)
    if current_user and current_user.may_publish?(statement_node)
      link_to(I18n.t('discuss.statements.publish'),
              publish_statement_url(:id => statement_node.id,
                                    :in => :summary),
              :class => 'ajax_put header_button text_button publish_text_button ttLink',
              :title => I18n.t('discuss.tooltips.publish'))
    else
      ''
    end
  end

  def truncate_statement_text(statement_document)
    text = Sanitize.clean(statement_document.text)
    text.mb_chars.length > 200 ? word_truncate(text, 150, 150) : text
  end

  # To be used to strip the rest letters of last / first words.
  def word_truncate(text, start_length, end_length, delimiter = ' ... ... ... ')
    text.mb_chars.length <= start_length + end_length ? text :
      text[/\A.{#{start_length}}\w*/m] + delimiter + text[/\w*.{#{end_length}}\Z/m]
  end


  #
  # linked title of question on my question area
  #
  def my_question_title(title,question)
    link_to(h(title),statement_node_url(question,
                                        :origin => :mi,
                                        :bids => :mi),
            :class => "statement_link ttLink no_border",
            :title => I18n.t("discuss.tooltips.read_#{question.u_class_name}"))
  end

  #
  # linked image of question on my question area
  #
  def my_question_image(question)
    link_to statement_node_url(question,
                               :origin => :mi,
                               :bids => :mi),
            :class => "avatar_holder" do
      image_tag question.image.url(:small)
    end
  end

  #
  # create question button above the discuss search results and on the left corner of my questions
  #
  def create_my_question_link_for
    link_to(new_question_url(:origin => :mi, :bids => :mi),
                       :id => 'create_question_link',
                       :class => 'add_new_button big_action_button') do
      link_content = ''
      link_content << content_tag(:span, '',
                      :class => "add_new_question_icon ttLink no_border",
                      :title => I18n.t("discuss.tooltips.create_question"))
      link_content <<  content_tag(:span, I18n.t("discuss.my_questions.add"),
                                   :class => 'label')
      link_content
    end
  end

  # Creates a 'Publish' button to release the question on my questions area.
  def publish_button_or_state(statement_node, opts={})
    if current_user and current_user.may_publish?(statement_node)
      link_to(I18n.t("discuss.statements.publish"),
              publish_statement_url({:id => statement_node.id}.merge(opts)),
              :class => 'ajax_put publish_button ttLink no_border',
              :title => I18n.t('discuss.tooltips.publish'))
    else
      opts[:no_published_label] ? '' : content_tag(:span ,
                                                   I18n.t('discuss.statements.states.published'),
                                                   :class => 'publish_button')
    end
  end

  # returns a collection from possible statement states to be used on radios and select boxes
  def statement_states_collection
    StatementState.all.map{|s| [I18n.t("discuss.statements.states.initial_state.#{s.code}"), s.id]}
  end
  
  def top_level_collection
    [true, false].map{|bool|[I18n.t("discuss.statements.top_level.initial_state.#{bool}_value"), bool]}
  end

  # renders pagination 'more' button
  def more_questions(statement_nodes, page=1)
    loaded_pages = statement_nodes.length / QUESTIONS_PER_PAGE.to_i +
                   (statement_nodes.length % QUESTIONS_PER_PAGE.to_i > 0 ? 1 : 0)
    content_tag :div, :class => 'more_pagination' do
      if statement_nodes.current_page != statement_nodes.total_pages
      link_to I18n.t("application.general.more"),
              discuss_search_url(:search_terms => params[:search_terms],
                                 :page => page.to_i + loaded_pages),
              :class => 'more_children ajax'
      else
        content_tag :span, I18n.t("application.general.more"),
                    :class => 'disabled more_children'
      end
    end
  end
end