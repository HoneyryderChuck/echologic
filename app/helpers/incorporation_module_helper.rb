module IncorporationModuleHelper

  #############
  # DRAFTABLE #
  #############

  def incorporable?(statement_node, statement_document, parent_document, opts={})
    !opts[:being_incorporated] &&
    (!current_user or
     (statement_node.published? and
      parent_document.language == statement_node.drafting_language and
      statement_document.language. == statement_node.drafting_language and
      ((statement_node.times_passed == 0 and statement_document.author == current_user) or
       (statement_node.times_passed == 1 and statement_node.supported?(current_user)))))
  end

  def incorporate_statement_node_link(parent_node, statement_node)
    link_to(incorporate_statement_node_url(parent_node, :approved_ip => statement_node.id, :cs => @node_environment.current_stack.to_s),
           :id => 'incorporate_link',
           :class => 'ajax') do
      content_tag(:span, '',
                  :class => "incorporate_statement_button_mid ttLink no_border",
                  :title => I18n.t("discuss.tooltips.incorporate"))
    end
  end

end