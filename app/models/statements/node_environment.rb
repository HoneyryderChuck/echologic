class NodeEnvironment < Struct.new(:new_level, :bids, :origin, :alternative_modes, :hub)
  
  include ActionController::UrlWriter
  
  
  
  
  #   class: BidContainer
  #    
  #   defines the container type that stores the bids (nothing more than an array containing the bids)
  #   
  class Container < Array
    
    def to_s
      self.map(&:to_s).join(",")
    end
  end
  
  
  
  #   class: Pair
  #  
  #   Defines the type of structure used to represent an argument representing a key and a value from the url of a statement
  #   
  #    key:   String(length=2):   can be dq (discuss search), sr (search results), mi (my questions), jp (jump from), fq(follow up question)
  #    value: String:             can be a '@term|@page', '|@page', or '@statement_node_id' representation
  #    page:  Integer:            page filtered from value (when one exists)
  #    terms: String:             search terms filtered from value 
  class Pair < Struct.new(:key, :value)
    
    attr_accessor :page, :terms
    
    def initialize(key, value)
      if %w(ds sr mi).include?(key)
        term_and_page = value.split('|')
        @terms = Breadcrumb.decode_terms(term_and_page[0])
        @page = term_and_page[1].to_i
      end
      super
    end
    
    def to_s
      "#{self.key}#{self.value}"
    end
  end
  
  
  
  def initialize(new_level, bids, origin, alternative_modes, hub)
    # new level
    self.new_level = true if !new_level.blank?
    
    # breadcrumb ids
    if bids.blank?
      self.bids = []
    else
      cont = Container.new
      bids.split(",").each{|bid| cont << Pair.new(bid[0,2], CGI.unescape(bid[2..-1]))}
      self.bids = cont
    end
    
    # origin
    self.origin = origin.blank? ? nil : Pair.new(origin[0,2], CGI.unescape(origin[2..-1]))
    
    # alternative_levels
    if alternative_modes.blank?
      self.alternative_modes =  []
    else
      cont = Container.new
      alternative_modes.split(",").map(&:to_i).each{|al| cont << al }
      self.alternative_modes = cont
    end
    
    # hub (important for the creation of alternatives)
    self.hub = Pair.new(hub[0,2], hub[2..-1]) if !hub.blank?
  end
  
  def add_bid(bid)
    self.bids + [bid]
  end
  
  def pop_bid
    cp = self.bids.clone
    cp.pop
    cp
  end
  
  
  def add_alternative_mode(al)
    (self.alternative_modes + [al]).uniq
  end
  
  def pop_alternative_mode
    cp = self.alternative_modes.clone
    cp.pop
    cp
  end
  
  def remove_alternative_mode(level)
    cp = self.alternative_modes.clone
    cp - [level]
  end
  
  def new_level?
    self.new_level.eql?(true)
  end
  
  def bids?
    !self.bids.blank?
  end
  
  def alternative_modes?
    !self.alternative_modes.blank?
  end
  
  def hub?
    self.hub.present?
  end
  
end