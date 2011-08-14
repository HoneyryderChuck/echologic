module EchoableModuleHelper

  # Inserts a status bar based on the support ratio value.
  # (The support ratio is the calculated ratio for a statement_node,
  # representing and visualizing the agreement a statement_node has found within the community.)
  def supporter_ratio_bar(statement_node,
                          previous_statement = statement_node.parent_node,
                          type = statement_node.class.name)
    # TODO:How to spare calculating this label two times (see next method, they're almost always sequencially triggered)
    label = supporters_number(statement_node)
    if !statement_node.nil? and (statement_node.new_record? or statement_node.ratio(previous_statement,type) > 1)
      content_tag(:span, '',
                  :class => "echo_indicator supporters_bar ttLink",
                  :title => label,
                  :alt => statement_node.new_record? ? 10 : statement_node.ratio(previous_statement,type))
    else
      content_tag(:span, '',
                  :class => "no_echo_indicator supporters_bar ttLink",
                  :title => label)
    end
  end


  # Inserts a supporters label with the supporters number of this statement
  def supporters_label(statement_node, show_label = false)
    label = supporters_number(statement_node)
    content_tag(:span, label, :class => "supporters_label", :style => "#{show_label ? '' : 'display:none' }")
  end


  # Returns the right line that shows up below the ratio bar (1 supporter, 2 supporters...)
  def supporters_number(statement_node)
    I18n.t("discuss.statements.echo_indicator.#{statement_node.supporter_count == 1 ? 'one' : 'many'}",
           :supporter_count => statement_node.new_record? ? 1 : statement_node.supporter_count)
  end

  # Render the appropriate echo button onto the action bar
  def render_echo_button(statement_node)
    statement_node.new_record? ? new_form_echo_button(statement_node) : show_echo_button(statement_node)
  end


  # Renders echo button on new statement forms
  def new_form_echo_button(statement_node)
    echo_button :div, true, statement_node, :class => 'new_record' do |button|
      button << hidden_field_tag('echo', true)
    end
  end

  # Renders echo button on statement views
  def show_echo_button(statement_node)
    echoed = current_user && statement_node.supported?(current_user)
    href = echoed ? unecho_statement_node_url(statement_node) : echo_statement_node_url(statement_node)
    content = ''
    content << echo_button(:a, echoed, statement_node, :href => href)
    content << social_echo_container(statement_node, echoed)
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
      button = ''
      button << content_tag(:span, '', :class => 'echo_button_icon')
      button << echo_button_label(statement_node)
      button << content_tag(:span, '', :class => 'error_lamp')
      yield button if block_given?
      button
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
      content = ''
      content << content_tag(:span, '', :class => 'social_echo_button expandable',
                  :href => social_widget_statement_node_url(statement_node, :bids => params[:bids], :origin => params[:origin]),
                  :style => "#{echoed ? '' : 'display:none'}")
      content
    end
  end

  def social_echo_panel(statement_node)
    render :partial => 'statements/social_widget',
           :locals => {:statement_node => statement_node}
  end

  def render_social_account_buttons(statement_node)
    content_tag(:div,
                :class => "social_account_list block center",
                'data-enabled' => I18n.t("users.social_accounts.share.enabled"),
                'data-disabled' => I18n.t("users.social_accounts.share.disabled")) do
      content = ''
      token_url = redirect_from_popup_to(add_remote_url,
                                         :redirect_url => statement_node_url(statement_node,
                                                                         :bids => params[:bids],
                                                                         :origin => params[:origin]),
                                         :later_call => social_widget_statement_node_url(statement_node,
                                                                                         :bids => params[:bids],
                                                                                         :origin => params[:origin]))
      %w(facebook twitter yahoo! linkedin).each do |provider|
        connected = current_user.has_provider? provider
        css_provider = provider.eql?('yahoo!') ? 'yahoo' : provider
        css_classes = "social_label #{css_provider}#{connected ? ' connected' : ''}"
        content << content_tag(:div, :class => "social_account #{css_provider}") do
          button = ''
          if connected
            button << link_to('', connected.identifier, :target => "_blank", :class => css_classes)
            button << provider_switch_button(provider, true)
          else
            button << content_tag(:span, '', :class => css_classes)
            button << provider_connect_button(provider, token_url)
          end
          button
        end
      end
      content
    end
  end

  def provider_switch_button(provider, enable = false)
    tag = enable ? 'enabled' : 'disabled'
    content = ''
    content << content_tag(:span, '', :class => "button #{tag}")
    content << hidden_field_tag("providers[#{provider}]", tag)
    content
  end

  def provider_connect_button(provider, token_url)
    content_tag :a, I18n.t("users.social_accounts.connect.title"),
                :href => SocialService.instance.get_provider_auth_url(provider, token_url),
                :class => 'button connect',
                :onClick => "return popup(this, null);"
  end
end