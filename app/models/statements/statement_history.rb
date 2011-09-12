class StatementHistory < ActiveRecord::Base
  
  # Main foreign keys
  belongs_to :statement
  belongs_to :statement_document
  
  # Secondary foreign keys
  belongs_to :old_document, :class_name => 'StatementDocument'
  belongs_to :incorporated_node, :class_name => 'StatementNode'
    
  belongs_to :author, :class_name => "User"
    
  delegate :language, :language_id, :to => :statement_document
  
  has_enumerated :action, :class_name => 'StatementAction'
  
  # Validations
  
  validates_presence_of :author_id
  validates_presence_of :action_id
  validates_associated :author

  before_create :load_statement
  
  def load_statement
    self.statement = statement_document.statement
  end
  
  #named scopes
  named_scope :by_language, lambda {|id|
  {:joins => :statement_document, :conditions => ["statement_documents.language_id = ?", id]}}
  named_scope :by_creation, :order => 'statement_histories.created_at ASC'
end
