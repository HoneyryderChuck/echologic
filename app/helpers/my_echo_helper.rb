module MyEchoHelper

  def social_account_button(provider, token_url)
    connected = current_user.has_provider? provider
    css_classes = "social_label #{provider.eql?('yahoo!') ? 'yahoo' : provider}#{connected ? ' connected' : ''}"
    if connected
      concat(
        link_to('', connected.identifier,
                    :target => "_blank",
                    :class => css_classes) +
        render(:partial => 'users/social_accounts/disconnect',
                           :locals => {:provider => provider})
      )
    else
      concat(
        content_tag(:span, '', :class => css_classes) +
        render(:partial => 'users/social_accounts/connect',
                           :locals => {:provider => provider,
                                       :token_url => token_url})
      )
    end
  end

  def component_link(method, type, entry)
    label = I18n.t("application.general.#{method}")
    path = send("#{method.eql?('delete') ? 'user' : "#{method}_user"}_#{type}_path", entry.user, entry)
    css = "#{method.eql?('delete') ? 'ajax_delete' : 'ajax'} text_button #{method}_text_button"
    link_to label, path, :class => css
  end
end