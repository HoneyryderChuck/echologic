# Specification of a Question

# * though the class is called Question, it is commonly refered to as a 'Debate' (in ui, and in concepts).
# * currently a Debate only expects one type of children, Proposals

class Question < StatementNode

  # Deletion handling - also delete all FUQs referencing this question
  has_many :follow_up_questions,           :class_name => "FollowUpQuestion",            :foreign_key => 'question_id', :dependent => :destroy
  has_one  :discuss_alternatives_question, :class_name => "DiscussAlternativesQuestion", :foreign_key => 'question_id', :dependent => :destroy

  has_children_of_types [:Proposal,true],[:BackgroundInfo,true]
  has_linkable_types



  # since the root node was created without a specific root node assigned, assign it after the creation 
  def create(*attrs)
    super
    init_self_as_root
  end
  
  def init_self_as_root
    self.update_attribute(:root_id, target_id) if !self.class.is_top_statement?
  end

  def publishable?
    true
  end

  def self.publishable?
    true
  end

  def is_referenced?
    !follow_up_questions.empty? or discuss_alternatives_question.present?
  end
end
