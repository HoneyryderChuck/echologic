class StatementDocument < ActiveRecord::Base

  belongs_to :author, :class_name => "User"
  belongs_to :statement
  
  validates_presence_of :title
  validates_presence_of :text
  validates_associated :author
  validates_presence_of :author
  
  named_scope :original, lambda {
    { :conditions => { :translated_document_id => nil }, :limit => 1 } }

  named_scope :siblings_of, lambda { |other|
    { :conditions => { :statement_id => other.statement_id } }
  }
  
  
  # returns all siblings of the document (= all translation, including the original, if self isn't the original)
  def siblings
    self.class.siblings_of(self)
  end
  
  # returns if the document is an original or a translation
  def original?
    self.translated_document_id.nil?
  end 
    
end
