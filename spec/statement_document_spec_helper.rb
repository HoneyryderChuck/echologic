module StatementDocumentSpecHelper

  fixtures :statements

  # returns a hash of required attributes for a valid statement document
  def valid_statement_document_attributes
    { :statement_id => statements(:first_proposal).id,
      :title => 'This is a statements title',
      :text => 'This is my statements text, you know?',
      :language_id => 'en'
    }
  end

  # returns one original statement_document (to be translated)
  # FIXME: FIXME!
  def one_original_statement_document
    
  end
end
