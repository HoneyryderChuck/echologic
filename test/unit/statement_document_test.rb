require 'test_helper'

class StatementDocumentTest < Test::Unit::TestCase
  
   
  context "creating a document" do
    setup do
      @document = valid_document
    end
    
    should "be valid" do
     @document.should be_valid
    end
    
    should "not save without an author" do
     @document.author = nil
     @document.should_not be_valid
    end
  
    should "not save without a title" do
      @document.title = nil
      @document.should_not be_valid
    end
    
    should "not save without a text" do
      @document.text = nil
      @document.should_not be_valid
    end
    
    should "validate presence of author, text and title" do 
      @document.should_validate_presence_of :author, :text, :title
    end
  end
 
  context "loading a document" do
    setup do
      @document = StatementDocument.first
    end
    
    should "have a user associated as an author" do
      assert @document.author.kind_of?(User)
    end
  end
  
  private
  
  # returns a hash of required attributes for a valid statement document
  def valid_statement_document_attributes
    { :statement_id => statements(:first_proposal).id,
      :title => 'This is a statements title',
      :text => 'This is my statements text, you know?',
      :language_id => 'en'
    }
  end
  
  def valid_document
    @document = StatementDocument.new(valid_statement_document_attributes)
  end
    
end

  
 context "translateable statements" do
    
    fixtures :statement_document

    setup do
      @statement_document = StatementDocument.new 
    end

    specify "should know what language it is in" do
      @statement_document.attributes = valid_statement_document_attributes.except(:language_id)
      @statement_document.should_not_be_valid
      @statement_document.language_id = 'en'
      @statement_document.should_be_valid
    end

    specify "can be a translation of another statement" do
      @statement_document.attributes = valid_statement_document_attributes
      @statement_document.translated_document_id = one_original_statement_document.id
      @statement_document.save!
      @statement_document.original.should_be one_original_statement_document
    end

    specify "should be able to have translations" do
      @statement_document.attributes = valid_statement_document_attributes
      @statement_document.save!
      @translated_statement_document = StatementDocument.new
      @translated_statement_document = valid_statement_document_attributes
      @translated_statement_document.translated_document_id = @statement_document.id
      @statement_document.translation.should_be [@translated_statement_document]
    end

    specify "should tell if it is the original document" do
      @statement_document.attributes = valid_statement_document_attributes
      @statement_document.save!
      @statement_document.original?.should_be true
      @statement_document.translated_document_id = one_original_statement_document.id
      @statement_document.save!
      @statement_document.original?.should_be false
    end

    specify "should always belong to a statement" do
      @statement_document.attributes = valid_statement_document_attributes.except(:statement_id)
      @statement_document.should_not_be_valid
      @statement_document.statement_id = valid_statement_document_attributes(:statement_id)
      @statement_document.should_be_valid
    end

  end
  
  


  # returns one original statement_document (to be translated)
  # FIXME: FIXME!
  def one_original_statement_document
    
  end
  
end
