class Statement < ActiveRecord::Base
  include Echoable
  
  # magically allows Proposal.first.question? et al.
  #
  # FIXME: figure out why this sometimes doesn't work, but only in ajax requests
#  def method_missing(sym, *args)
#    sym.to_s =~ /\?$/ && ((klass = sym.to_s.chop.camelize.constantize) rescue false) ? klass == self.class : super
#  end
  
  # static for now
  
  def proposal?
    self.class == Proposal
  end
  
  def improvement_proposal?
    self.class == ImprovementProposal
  end
  
  def question?
    self.class == Question
  end
  
  ##
  ## ASSOCIATIONS
  ##

  belongs_to :creator, :class_name => "User"
  #belongs_to :document, :class_name => "StatementDocument"
  
  # We need to be absolutely sure about how to decide which translation of a statemen document we want to display
  # 
  # Possible solutions are:
  # 1. the original, if it is in the users default language
  # 2. any translation in the users default language
  # 3. any translation in one of the users other languages (sorted by the users ability to speak / read it)
  #
  # 1. the original, if it is in any language spoken by the user
  # 2. any other translation in any of the users spoken languages
  #
  # 1. the translation matching the users spoken languages best
  
  
  has_many :documents, :class_name => "StatementDocument" do 
    # this query returns translation for a statement ordered by the users prefered languages
    # OPTIMIZE: this should be built in sql
    def for_languages(lang_codes)
      # doc = find(:all, :conditions => ["translated_statement_id = ? AND language_code = ?", nil, lang_codes.first]).first
      find(:all, :conditions => ["language_code IN (?)", lang_codes]).sort { |a, b| lang_codes.index(a.language_code) <=> lang_codes.index(b.language_code)}.first
    end
  end
  
  has_one :author, :through => :document

  belongs_to :root_statement, :foreign_key => "root_id", :class_name => "Statement"
  acts_as_tree :scope => :root_statement
  
  belongs_to :category, :class_name => "Tag"

  # not yet implemented

  #belongs_to :work_packages

  # allow mass-assignment of document data.
  # FIXME: there has to be some more convenient way of doing this...
  #def document=(obj)
    #obj.kind_of?(Hash) ? (document ? document.update_attributes!(obj) : documents.create(obj)) : super
    #super
  #end ; alias :statement_document= :document=

  # returns the actual document that we will display to the user
  #def document
  #  documents.original.for_languages('en') || documents.for_languages(['en'])
  #end
  
  # returns a translated document for passed language_codes (or nil if none is found)
  def translated_document(lang_codes)
    @current_document ||= documents.for_languages(lang_codes)
  end
  
  def document
    raise "Statement#document is deprecated. Use helper document(statement) instead."
  end
  
  ##
  ## NAMED SCOPES
  ##
    
  named_scope :proposals, lambda {
    { :conditions => { :type => 'Proposal' } } }
  named_scope :improvement_proposals, lambda {
    { :conditions => { :type => 'ImprovementProposal' } } }
  named_scope :arguments, lambda {
    { :conditions => ['type = ? OR type = ?', 'ProArgument', 'ContraArgument'] } }
  named_scope :pro_arguments, lambda {
    { :conditions => { :type => 'ProArgument' } } }
  named_scope :contra_arguments, lambda {
    { :conditions => { :type => 'ContraArgument' } } }
  
  named_scope :published, lambda {|auth| 
    { :conditions => { :state => @@state_lookup[:published] } } unless auth }
  
  # orders

  named_scope :by_ratio, :include => :echo, :order => '(echos.supporter_count/echos.visitor_count) DESC'

  named_scope :by_supporters, :include => :echo, :order => 'echos.supporter_count DESC'

  # category

  named_scope :from_category, lambda { |value|
    { :include => :category, :conditions => ['tags.value = ?', value] } }
  
  ## ACCESSORS
  
  def title
    raise "Statement#title is deprecated. Use document(statement).title instead."
  end

  def text
    raise "Statement#text is deprecated. Use document(statement).text instead."
  end

  def level
    # simple hack to gain the level
    # problem is: as we can't use nested set (too write intensive stuff), we can't easily get the statements level in the tree
    level = 0
    level += 1 if self.parent
    level += 1 if self.root && self.root != self && self.root != self.parent
    level
  end

  ##
  ## STATES
  ##
  
  cattr_reader :states, :state_lookup
  
  # Map the different states of statements to their database representation
  # value.
  # TODO: translate them ..
  @@states = [:new, :published]
  @@state_lookup = { :new => 0, :published => 1 }
  
  # Validate that state is correct
  validates_inclusion_of :state, :in => Statement.state_lookup.values
  
  ##
  ## VALIDATIONS
  ##

  validates_presence_of :creator
  validates_associated :creator
  
  # i had to remove validations for document, because we need to save the statement independently from its document (the document needs a statement_id)
  # validates_presence_of :document
  # validates_associated :document
  validates_presence_of :category
  
  def validate
    # except of questions, all statements need a valid parent
    errors.add("Parent of #{self.class.name} must be of one of #{self.class.valid_parents.inspect}") unless self.class.valid_parents and self.class.valid_parents.select { |k| parent.instance_of?(k.to_s.constantize) }.any?
  end

  # recursive method to get all parents...
  def parents(parents = [])
    obj = self
    while obj.parent && obj.parent != obj
      parents << obj = obj.parent
    end
    parents.reverse!
  end

  def self_with_parents()
    list = parents([self])
    list.size == 1 ? list.pop : list
  end
  
  # the main expected child type (neccessary for prev / next functionality)
  def expected_child_type
    self.class.expected_children.first.to_s.underscore
  end

  class << self
    
    # returns valid parent statements for this statement (e.g. proposal -> question)
    def valid_parents
      @@valid_parents[self.name]
    end

    # returns valid / expected children for this statement (e.g. question -> proposal)
    def expected_children
      @@expected_children[self.name]
    end
    
    # the default scope defines basic rules for the sql query sent on this model
    # by default we include the echo-relation and bring them in order of being most supported / most recent
    # FIXME: this should move to lib/echoable.rb if possible
    def default_scope
      { :include => :echo,
        :order => %Q[echos.supporter_count DESC, created_at ASC] }
    end
    
    # returns the display_name of the statement / can be overwritten by subclases - default is class name humanized
    def display_name
      self.name.underscore.gsub(/_/,' ').split(' ').each{|word| word.capitalize!}.join(' ')
    end
    
    def expected_parent_chain
      chain = []
      obj_class = self.name.constantize
      while !obj_class.valid_parents.first.nil?
        chain << obj = self.valid_parents.first
      end
      chain
    end

    private
    # takes an array of class names that are valid for the parent association.
    # the class names should either be strings or symbols, no constants. They
    # will be constantized within the instance, hence won't place a loading
    # constraint on the models (which might lead to loops in our case)
    def validates_parent(*klasses)
      @@valid_parents ||= { }
      @@valid_parents[self.name] ||= []
      @@valid_parents[self.name] += klasses
    end

    # takes an array of class names that are expected to be children of this class
    # this could also be generated by checking all other subclasses valid_parents
    # but i think it is more convenient to define them extra
    # at the moment we only show one type of children in the questions children container (view)
    # therefor we will look for the first element of the expected_children array
    def expects_children(*klasses)
      @@expected_children ||= { }
      @@expected_children[self.name] ||= []
      @@expected_children[self.name] += klasses
    end
  end
end
