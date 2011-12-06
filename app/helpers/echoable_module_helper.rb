module EchoableModuleHelper

  # Returns the right line that shows up below the ratio bar (1 supporter, 2 supporters...)
  def supporters_number(statement_node)
    I18n.t("discuss.statements.echo_indicator.#{statement_node.supporter_count == 1 ? 'one' : 'many'}",
           :supporter_count => statement_node.new_record? ? 1 : statement_node.supporter_count)
  end

  #
  # Renders echo button
  # button_tag : symbol : html tag that contains the elements
  # echoed: true/false : whether button state is echoed or not
  # type : string (statement_node class) : selects the right label
  #
  def echo_button(button_tag, echoed, statement_node, opts={})
    opts[:class] ||= ''
    opts[:class] << " echo_button #{echoed ? '' : 'not_'}supported"

    content_tag(button_tag, opts) do
      
      concat(
        content_tag(:span, '', :class => 'echo_button_icon') + 
        echo_button_label(statement_node) + 
        content_tag(:span, '', :class => 'error_lamp')
      )
    end
  end

  def echo_button_label(statement_node)
    content_tag(:span, '',
                :class => 'label',
                'data-not-supported' => I18n.t("discuss.statements.echo_link"),
                'data-supported' => I18n.t("discuss.statements.unecho_link"))
  end

  def social_echo_container(statement_node, echoed=false)
    content_tag(:div, :class => 'social_echo_container') do
      content_tag(:span, '', :class => 'social_echo_button expandable',
                  :href => social_widget_statement_node_url(statement_node, :bids => @node_environment.bids.to_s, :origin =>@node_environment.origin.to_s),
                  :style => "#{echoed ? '' : 'display:none'}")
    end
  end


  def provider_switch_button(provider, enable = false)
    tag = enable ? 'enabled' : 'disabled'
    concat(
      content_tag(:span, '', :class => "button #{tag}") +
      hidden_field_tag("providers[#{provider}]", tag)
    )
  end

  def provider_connect_button(provider, token_url)
    content_tag :a, I18n.t("users.social_accounts.connect.title"),
                :href => SocialService.instance.get_provider_auth_url(provider, token_url),
                :class => 'button connect',
                :onClick => "return popup(this, null);"
  end
end