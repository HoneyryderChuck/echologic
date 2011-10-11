#   class: NodeEnvironment
#  
#   Encapsulates all the external values to the statement node itself that play a part in the various workflows
#   
#    new_level:         Boolean:            tells if the current action will result in the renderization of the statement node on a level below (TODO: later this will store the animation type)
#    bids:              Container(Pair):    stores the breadcrumb identifiers of the current action
#    origin:            Pair:               stores the identifier of the origin of the root node of the current tree (or subtree)
#    alternative_modes: Container(Integer): stores the level of the statement nodes currently displayed on alternative mode
#    hub:               Pair:               stores the identifier of the "hub" sibling statement node (used on the creation of alternatives)
#    current_stack:     Container(Integer): stores the statement node identifiers of the currently display statement stack
#    level:             Integer:            level at which the current statement (or teaser) will be displayed
class NodeEnvironment < Struct.new(:new_level, :bids, :origin, :alternative_modes, :hub, :current_stack, :level)
  
  include ActionController::UrlWriter
  
  
  
  
  #   class: BidContainer
  #    
  #   defines the container type that stores the bids (nothing more than an array containing the bids)
  #   
  class Container < Array
    
    def initialize(o)
      if o.kind_of? String
        o = o.split(",").map(&:to_i)         
      end
      self.concat(o)
    end
    
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
  
  
  
  def initialize(statement_node, node_type, new_level, bids, origin, alternative_modes, hub, current_stack)
    # new level
    self.new_level = true if !new_level.blank?
    
    # breadcrumb ids
    self.bids = bids.blank? ? [] : Container.new(bids.split(",").map{|bid| Pair.new(bid[0,2], CGI.unescape(bid[2..-1]))})
    
    # origin
    self.origin = origin.blank? ? nil : Pair.new(origin[0,2], CGI.unescape(origin[2..-1]))
    
    # alternative_levels
    self.alternative_modes =  alternative_modes.blank? ? [] : Container.new(alternative_modes)
    
    # hub (important for the creation of alternatives)
    self.hub = Pair.new(hub[0,2], hub[2..-1]) if !hub.blank?
    
    # current stack (visible statements)
    self.current_stack = current_stack.blank? ? [] : current_stack.split(",").map(&:to_id)
    
    # level
    if statement_node.present? and statement_node.new_record?
      inc = self.hub? ? 0 : 1
      self.level = (statement_node.parent_node.nil? or node_type.is_top_statement?) ? 0 : statement_node.parent_node.level + inc
    else
      self.level = self.current_stack? ? self.current_stack.length - 1 : nil
    end
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
  
  def current_stack?
    !self.current_stack.blank?
  end
  
  def previous_statement_node(statement_node)
    return nil if self.current_stack.blank? or statement_node.nil? or statement_node.level.eql?(0)
    StatementNode.find(previous_id(statement_node), :select => "id, lft, rgt, question_id") 
  end
  
  def previous_id(statement_node)
    index = self.current_stack.index(statement_node.id)
    self.current_stack[index-1]
  end
  
  def stack_level(statement_node)
    return statement_node if statement_node.kind_of? Integer
    self.current_stack? ? self.index(statement_node.id) : statement_node.level
  end
  
end