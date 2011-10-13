class FollowUpQuestion < Question
  has_children_of_types [:Proposal,true],[:BackgroundInfo,true]
  has_linkable_types :Question
  
  belongs_to :question
  
  delegate :level, :ancestors, :topic_tags, :topic_tags=, :tags, :taggable?, :echoable?, :editorial_state_id,
           :editorial_state_id=, :published, :locked_at, :supported?, :taggable?, :creator_id=,
           :creator_id, :creator, :author_support, :ancestors, :target_id, :target_root_id, :to => :question
  
  validates_associated :question
  
  before_create :initialize_echo
  
  named_scope :by_statement_state, lambda { |user|
    creator = user ? user.id : -1
    {
      :joins => " LEFT JOIN #{Statement.table_name} ON #{self.table_name}.statement_id = #{Statement.table_name}.id",
      :conditions => ["(#{Statement.table_name}.editorial_state_id = ? OR #{self.table_name}.creator_id = ?)",
                      StatementState['published'].id, creator]
    }
  }
  
  def initialize_echo
    self.echo = self.question.echo  
  end
  
  def target_statement
    self.question
  end
  
  def initialize(attrs)
    question_attrs = attrs.clone
    
    existing_statement = Statement.find(question_attrs[:statement_attributes][:id]) if question_attrs[:statement_attributes][:id].present?
    attrs[:question] = existing_statement.nil? ? Question.new({:parent_id => "", :root_id => ""}.merge(question_attrs)) : existing_statement.statement_nodes.all(:conditions => "type = 'Question'").first
    
    attrs.delete(:statement_attributes)
    attrs.delete(:creator_id)
    attrs[:creator] = attrs[:question].creator
    attrs[:echo] = attrs[:question].echo
    attrs[:statement] = attrs[:question].statement
    super
  end
  
  
  #################################################
  # string helpers (acts_as_echoable overwriting) #
  #################################################
  
  
  
  class << self
    
    # helper function to differentiate this model as a level 0 model
    def is_top_statement?
      true
    end
  end
end