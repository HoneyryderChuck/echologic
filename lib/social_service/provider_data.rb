
class ProviderData

  attr_accessor :name, :url, :requires_input

  def initialize(name, url, requires_input = false)
    self.name = name
    self.url = url
    self.requires_input = requires_input
  end

end