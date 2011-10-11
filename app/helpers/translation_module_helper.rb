module TranslationModuleHelper
  #
  # Creates a link to translate the current document in the current language.
  #
  def create_translate_statement_link(statement_node, statement_document, css_class = "",type = node_type(statement_node))
    link = image_tag 'page/translation/babelfish_left.png', :class => 'fish_left'
    link << content_tag(:span, statement_document.language.value.upcase, :class => "language_label from_language")
    link << link_to(I18n.t('discuss.translation_request'),
             new_translation_statement_node_url(statement_node, :current_document_id => statement_document.id,
                                                                :cs => @node_environment.current_stack.to_s),
             :class => "ajax translation_link #{css_class}")
    link
  end
  
  # Loads images for the translation box
  def translation_upper_box(language_from, language_to)
    val = "#{image_tag 'page/translation/babelfish_left.png', :class => 'fish_left'}"
    val << (content_tag :span, language_from, :class => 'language_label from_language')
    val << "#{image_tag 'page/translation/translation_arrow.png',:class => 'arrow'}"
    val << "#{image_tag 'page/translation/babelfish_right.png', :class => 'fish_right'}"
    val << (content_tag :span, language_to, :class => "language_label to_language")
    val
  end
end