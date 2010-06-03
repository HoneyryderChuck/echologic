module EchoHelper

  # TODO depricated
  def echo_button(statement_node)
    url_options = { :controller => statement_node.class.name.underscore.pluralize, :id => statement_node.id }
    unless current_user.supported?(statement_node)
      link_to_remote '<div>&nbsp;</div>', { :url => url_options.merge(:action => 'echo'), :method => :put}
    else
      link_to_remote '<div>&nbsp;</div>', { :url => url_options.merge(:action => 'unecho'), :method => :delete, :html => {:class => 'active'} }
    end
  end

end
