require 'test_helper'

class StatementsControllerText < ActionController::TestCase
  context "creating a new debate" do 
    setup { post :create, :question => { :text => "This is a question", :title => "af" } }
    should_change { Question.count }
    should_change  { StatementDocument.count }
    should_redirect_to { question_url(@statement) }
  end
end
