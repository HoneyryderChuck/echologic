class StatementNode < ActiveRecord::Base
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
  has_one :author, :through => :document

  belongs_to :root_statement, :foreign_key => "root_id", :class_name => "StatementNode"
  acts_as_tree :scope => :root_statement
  
  #belongs_to :category, :class_name => "Tag"
  
  has_many :tao_tags, :as => :tao, :dependent => :destroy
  has_many :tags, :through => :tao_tags

  # not yet implemented

  #belongs_to :work_packages

  named_scope :by_title, lambda {|value|
  {:joins => [:statement_documents], :conditions => ["statement_documents.title like ?", "%"+value+"%"]}}

  # allow mass-assignment of document data.
  # FIXME: there has to be some more convenient way of doing this...
  # def document=(obj)
  #   obj.kind_of?(Hash) ? (document ? document.update_attributes!(obj) : create_document(obj)) : super
  # end ; alias :statement_document= :document=

  belongs_to :statement
  has_many :statement_documents, :through => :statement do 
    # this query returns translation for a statement ordered by the users prefered languages
    # OPTIMIZE: this should be built in sql
      
    def for_languages(lang_ids)
      # doc = find(:all, :conditions => ["translated_statement_id = ? AND language_code = ?", nil, lang_codes.first]).first
      find(:all, :conditions => ["language_id IN (?)", lang_ids]).sort { |a, b| lang_ids.index(a.language_id) <=> lang_ids.index(b.language_id)}.first
    end
  end
    
  # returns a translated document for passed language_codes (or nil if none is found)
  def translated_document(lang_ids)
    @current_document ||= statement_documents.for_languages(lang_ids)
  end
  
  def translated_document?(lang_ids)
    return statement_documents.for_languages(lang_ids).nil?
  end
   
  # creates a new statement_document
  def add_statement_document(attributes={ })
    doc = StatementDocument.new(attributes.merge(:statement_id => self.statement_id))
    self.statement.statement_documents << doc
    return doc
  end
  
  # creates and saves a  statement_document with given parameters a
  def add_statement_document!(*args)
    doc = StatementDocument.new(:statement_id => self.statement.id)
    doc.update_attributes!(*args)
    self.statement.statement_documents << doc
    return doc
  end
    
  ##
  ## NAMED SCOPES
  ##
    
  named_scope :questions, lambda {
    { :conditions => { :type => 'Question' } } }  
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
  
  named_scope :by_creation, :order => 'created_at DESC'

  #context
  named_scope :from_context, lambda { |context_ids|
    { :include => :tao_tags, :conditions => ['tao_tags.context_id IN (?)', context_ids] } }
  # tag

  named_scope :from_tags, lambda { |value|
    { :include => :tags, :conditions => ['tags.value = ?', value] } }
  
  
  ## ACCESSORS
  
  def title
    raise 'title is deprecated... please use translated_document().title instead'
    #self.translated_document(1).title
  end

  def text
    raise 'text is deprecated... please use translated_document().title instead'
    #self.translated_document(1).text
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
  validates_inclusion_of :state, :in => StatementNode.state_lookup.values
  
  ##
  ## VALIDATIONS
  ##

  validates_presence_of :creator_id
  validates_associated :creator
  validates_presence_of :statement_id
  validates_associated :statement
  
  after_destroy :delete_dependencies
  
  
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
  
  def delete_dependencies
    self.statement.destroy if self.statement.statement_nodes.empty?
  end

  class << self
    
    def search_statements(type, value, opts={} )
    
      #sorting the or arguments    
      or_attrs = opts[:or_attrs] || %w(d.title d.text)
      or_conditions = or_attrs.map{|attr|"#{attr} LIKE ?"}.join(" OR ")
      
      #sorting the and arguments    
      and_conditions = opts[:conditions] || ["n.type = '#{type}'"]
      and_conditions << "t.value = '#{opts[:tag]}'" unless opts[:tag].nil?
      and_conditions << "tt.tao_type = 'StatementNode'" unless opts[:tag].nil?
      and_conditions << "state = #{@@state_lookup[:published]}" if opts[:auth] 
      
      #all getting along like really good friends
      and_conditions << "(#{or_conditions})"
      
      #Rambo 1
      query_part_1 = <<-END
        select distinct n.*
        from
          statement_nodes n
          LEFT JOIN statements s             ON n.statement_id = s.id
          LEFT JOIN statement_documents d    ON s.id = d.statement_id
          LEFT JOIN tao_tags tt              ON tt.tao_id = n.id
          LEFT JOIN tags t                   ON tt.tag_id = t.id
          LEFT JOIN echos e                  ON n.echo_id = e.id
        where
      END
      #Rambo 2
      query_part_2 = and_conditions.join(" AND ")
      #Rambo 3
      #TODO: doesn't order by supporter count!!!!!!!!!!!!!!!
      query_part_3 = " order by n.created_at asc;"
      
      #All Rambo's in one
      query = query_part_1+query_part_2+query_part_3
      value = "%#{value}%"
       
      conditions = [query, *([value] * or_attrs.size)]
      statement_nodes = find_by_sql(conditions)
    end
  
    def valid_parents
      @@valid_parents[self.name]
    end

    def expected_children
      @@expected_children[self.name]
    end

    def default_scope
      { :include => :echo,
        :order => %Q[echos.supporter_count DESC, created_at ASC] }
    end
    
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
