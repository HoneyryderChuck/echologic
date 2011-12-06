module TranslationModuleHelper
  #
  # Creates a link to translate the current document in the current language.
  #
  def create_translate_statement_link(statement_node, statement_document, css_class = "",type = node_type(statement_node))
    image_tag('page/translation/babelfish_left.png', :class => 'fish_left') +
    content_tag(:span, statement_document.language.value.upcase, :class => "language_label from_language") +
    link_to(I18n.t('discuss.translation_request'),
           new_translation_statement_node_url(statement_node, :current_document_id => statement_document.id,
                                                              :cs => @node_environment.current_stack.to_s),
           :class => "ajax translation_link #{css_class}")
  end
  
  # Loads images for the translation box
  def translation_upper_box(language_from, language_to)
    image_tag('page/translation/babelfish_left.png', :class => 'fish_left') +
    content_tag(:span, language_from, :class => 'language_label from_language') +
    image_tag('page/translation/translation_arrow.png',:class => 'arrow') +
    image_tag('page/translation/babelfish_right.png', :class => 'fish_right') +
    content_tag(:span, language_to, :class => "language_label to_language") 
  end
end