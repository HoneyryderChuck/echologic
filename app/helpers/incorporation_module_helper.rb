module IncorporationModuleHelper

  #############
  # DRAFTABLE #
  #############

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