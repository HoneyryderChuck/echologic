class StatementDocument < ActiveRecord::Base

  EDIT_LOCKING_TIME = 1.hours

  belongs_to :statement
  has_many :statement_nodes, :through => :statement, :source => :statement_nodes

  has_one :statement_history, :dependent => :destroy

  belongs_to :locked_by, :class_name => "User", :foreign_key => 'locked_by'

  has_enumerated :language, :class_name => 'Language'

  validates_presence_of :title
  validates_length_of :title, :maximum => 101
  validates_presence_of :text
  validates_presence_of :language_id
  validates_associated :statement_history

  before_validation :set_history
  
  accepts_nested_attributes_for :statement_history
  
  delegate :action, :author, :incorporated_node, :old_document, :to => :statement_history, :allow_nil => true

  
  named_scope :current_documents, lambda { { :conditions => { :current => true } } }
  
  named_scope :by_statements, lambda { |statement_ids, extended_params|
    sel = %w(id title statement_id language_id)
    sel += extended_params if extended_params.present?
    {
      :select => "DISTINCT #{sel.map{|param| table_name + '.' + param }.join(', ')}",
      :include => :statement_history,
      :conditions => ["#{table_name}.statement_id IN (?)", statement_ids]
    }
  }
  
  named_scope :by_languages, lambda { |language_ids, match_original|
    return { :conditions => ["#{table_name}.language_id IN (?)", language_ids] } if !match_original
    {
      :joins => :statement,
      :conditions => ["(#{table_name}.language_id IN (?) OR #{table_name}.language_id = #{Statement.table_name}.original_language_id)", language_ids]
    }
  }

  def after_initialize
    self.build_statement_history if self.statement_history.nil?
  end

  def set_history
    self.statement_history.statement = self.statement
  end

  # Returns if the document is an original or a translation
  def original?
    self.old_document.nil?
  end

  # Returns the translated_document, declaring it as the original
  def original
    self.original? ? self : self.old_document.original
  end

  def lock(user)
    self.locked_by = user
    self.locked_at = Time.now
    save
  end

  def unlock
    self.locked_by = nil
    self.locked_at = nil
    save
  end

  # Returns all translations of self
  def translations
    #StatementDocument.find_all_by_translated_document_id(self.id)
    StatementDocument.all(:joins => :statement_history,
    :conditions => ["#{StatementHistory.table_name}.old_document_id = ? AND #{self.class.table_name}.language_id != ? AND current = 1",
                    self.id, self.language.id])
  end

  class << self
    
    #
    # returns an array of sql conditions representing a search for a term across the searchable fields
    # opts attributes:
    # term (String) : the term to search for
    #
    def term_conditions(term)
      conditions = Statement.extaggable_conditions_for_term(term, "d.tag")
      if (term.length > 3)
        conditions << sanitize_sql([" OR d.title LIKE ? OR d.text LIKE ?", "%#{term}%", "%#{term}%"])
      end
      conditions
    end
    
  end
end
