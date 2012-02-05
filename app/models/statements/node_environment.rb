#   class: NodeEnvironment
#  
#   Encapsulates all the external values to the statement node itself that play a part in the various workflows
#   
#    statement_node:    StatementNode       current statement node
#    new_level:         Boolean:            tells if the current action will result in the renderization of the statement node on a level below (TODO: later this will store the animation type)
#    bids:              Container(Pair):    stores the breadcrumb identifiers of the current action
#    origin:            Pair:               stores the identifier of the origin of the root node of the current tree (or subtree)
#    alternative_modes: Container(Integer): stores the level of the statement nodes currently displayed on alternative mode
#    hub:               Pair:               stores the identifier of the "hub" sibling statement node (used on the creation of alternatives)
#    current_stack:     Container(Integer): stores the statement node identifiers of the currently display statement stack
#    sids:              Container(Integer): stores the identifiers of the statement nodes to render
#    level:             Integer:            level at which the current statement (or teaser) will be displayed
#    expand:            boolean:            whether the statement is an expansion of a previous closed one
class NodeEnvironment < Struct.new(:statement_node, :new_level, :bids, :origin, :alternative_modes, :hub, :current_stack, :sids, :level, :expand)
  
  include ActionController::UrlWriter
  
  attr_accessor :ancestors, :node_type
  
  
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
    
    Breadcrumb.all_keys.each do |key|
      define_method :"#{key}?" do 
        self.key and self.key.eql?(key)
      end
    end
    
    def to_s
      "#{self.key}#{self.value}"
    end
  end
  
  
  
  def initialize(statement_node, node_type, options)
    
    self.statement_node = statement_node
    @node_type = node_type 
    
    # new level
    self.new_level = true if !options[:nl].blank?
    
    # breadcrumb ids
    self.bids = options[:bids].blank? ? [] : Container.new(options[:bids].split(",").map{|bid| Pair.new(bid[0,2], CGI.unescape(bid[2..-1]))})
    
    # origin
    self.origin = options[:origin].blank? ? nil : Pair.new(options[:origin][0,2], CGI.unescape(options[:origin][2..-1]))
    
    # alternative_levels
    self.alternative_modes =  options[:al].blank? ? [] : Container.new(options[:al])
    
    # hub (important for the creation of alternatives)
    self.hub = Pair.new(options[:hub][0,2], options[:hub][2..-1]) if !options[:hub].blank?
    
    # current stack (visible statements)
    self.current_stack = options[:cs].blank? ? [] : options[:cs].split(",").map(&:to_i)
    
    # sids (statements to render)
    self.sids = options[:sids].blank? ? [] : options[:sids].split(",").map(&:to_i)
    
    # level
    if statement_node.present? and statement_node.new_record?
      inc = self.hub? ? 0 : 1
      self.level = (statement_node.parent_node.nil? or node_type.is_top_statement?) ? 0 : statement_node.parent_node.level + inc
    else
      self.level = self.current_stack? ? self.current_stack.length - 1 : nil
    end
    
    # expand
    self.expand = options[:expand].present?
  end

  # CHECKERS
  
  def new_level? ; self.new_level.eql?(true) ; end
  def bids? ; !self.bids.blank? ; end
  def origin? ; self.origin.present? ; end
  def alternative_modes? ; !self.alternative_modes.blank? ; end
  def hub? ; self.hub.present? ; end
  def current_stack? ; !self.current_stack.blank? ; end
  def sids? ; !self.sids.blank? ; end
  def expand? ; self.expand ; end
  
  
  def add_bid(bid)
    self.bids + [bid]
  end
  
  def pop_bid
    self.bids.clone.pop
  end
  
  
  def add_alternative_mode(al)
    (self.alternative_modes + [al]).uniq
  end
  
  def pop_alternative_mode
    self.alternative_modes.clone.pop
  end
  
  def remove_alternative_mode(level)
    self.alternative_modes.clone - [level] 
  end
  
  
  # gets the previous node of a given node in the current stack
  def previous_statement_node(statement_node)
    return nil if self.current_stack.blank? or statement_node.nil? or statement_node.level.eql?(0)
    StatementNode.find(previous_id(statement_node), :select => "id, lft, rgt, question_id") 
  end
  
  # gets the previous node id of a give node in the current stack
  def previous_id(statement_node)
    index = self.current_stack.index(statement_node.id)
    self.current_stack[index-1]
  end
  
  # gets the current level of a given node in the stack
  def stack_level(statement_node)
    return statement_node if statement_node.kind_of? Integer
    self.current_stack? ? self.current_stack.index(statement_node.id) : statement_node.level
  end

  def statement_node_above(statement_node)
    if self.current_stack? # if there's a current stack, load the results from the stack
      if self.alternative_mode?(statement_node) # if statement is currently rendered as an alternative
        statement_node.hub # then prev must be the hub
      else
        self.previous_statement_node(statement_node)
      end
    else
      statement_node.parent_node # no current stack, so just load the damn parent
    end
  end
  
  # gets the ancestors of a given node in the current stack
  def ancestors
    @ancestors ||= self.sids? ? StatementNode.find(self.sids).sort{|s1, s2|s1.level <=> s2.level} : (self.statement_node.nil? ? [] : self.statement_node.ancestors)
  end
  
  
  # checks if a given node (or level) is rendered in alternative mode
  def alternative_mode?(statement_node_or_level)
    return true if self.hub?
    return false if !self.alternative_modes?
    statement_node_or_level = 0 if statement_node_or_level.nil?
    if statement_node_or_level.kind_of? Integer
      l = statement_node_or_level
    else
      stack_ids = self.current_stack if self.current_stack?
      stack_ids ||= (@ancestors + [self.statement_node]).map(&:id) if @ancestors.present?
      return false if stack_ids.nil?
      l = stack_ids.index(statement_node_or_level.id)
    end
    self.alternative_modes.include?(l)
  end
  
  # Loads information necessary to build a new breadcrumb
  def origin_params
    klass = case @node_type.name
      when "FollowUpQuestion" then "fq"
      when "DiscussAlternativesQuestion" then "dq"
    end
    
    [self.statement_node.parent_node, klass]
  end
  
  
end