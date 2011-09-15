require 'test_helper'

class StatementNodeTest < ActiveSupport::TestCase


  context "a statement node" do

    setup { @statement_node = Question.new }
    subject { @statement_node }

    should belong_to :statement
    should belong_to :creator
    should have_many :statement_documents
    

    
    # check for validations (should_validate_presence_of didn't work)
    %w(creator_id).each do |attr|
      context "with no #{attr} set" do
        setup { @statement_node.send("#{attr}=", nil)
          assert ! @statement_node.valid?
        }
        should("include #{attr} in it's errors") {
          assert @statement_node.errors[attr]
        }
      end
    end

    context("should be in a tree") do
      should have_db_column :root_id
      should have_db_column :parent_id
    end

    context("should be echoable") do
      should have_db_column :echo_id
      should belong_to :echo
      should have_many :user_echos
    end

    context "being saved" do
      setup do
        @statement_node = Question.new(:creator => User.first)
        @statement_node.build_statement(:original_language_id => Language.first.id, :topic_tags => "bebe")
        doc = @statement_node.statement.statement_documents.build(:title => 'A new Document',
                                                                  :text => 'with a very short body, dude!',
                                                                  :language_id => Language.first.id,
                                                                  :current => 1,
                                                                  :statement_history_attributes => {
                                                                   :author => User.first,
                                                                   :action_id => StatementAction[:created].id,
                                                                 })
        @statement_node.statement.publish
        @statement_node.save!
      end

      should "be able to access its statement documents data" do
        assert_equal @statement_node.document_in_preferred_language([Language.first.id]).title, "A new Document"
        assert_equal @statement_node.document_in_preferred_language([Language.first.id]).text, "with a very short body, dude!"
      end


      # TODO: Enable test again
#      should "have have a creation event associated" do
#        @events = @statement_node.events
#        assert(@events.first.operation.eql?('new'))
#        result = JSON.parse(@events.first.event)
#
#        question = result['question']
#        statement = question['statement']
#        statement_documents = statement['statement_documents']
#        title = statement_documents.first['title']
#        assert(title.eql?('A new Document'))
#
#        question = result['question']
#        tao_tags = question['tao_tags']
#        tag = tao_tags.first['tag']['value']
#
#        assert(tag.eql?('bebe'))
#      end

      # TODO: Enable tests again
#      should "should be followed by creator" do
#        @user = @statement_node.creator
#        assert (@statement_node.followed_by?(@user) or Delayed::Job.last.name[9..22] == "add_subscriber")
#      end

      should "be able to be visited" do
        @user = User.last
        @statement_node.visited!(@user)
        assert(@statement_node.visited?(@user))
      end

      should "be able to be supported" do
        @user = User.last
        @statement_node.visited!(@user)
        assert(@statement_node.visited?(@user))
      end

      # TODO: Enable tests again
#      should "be able to be followed" do
#        @user = User.last
#        @user.find_or_create_subscription_for(@statement_node)
#        assert(@user.follows?(@statement_node))
#      end

    end

  end # main context

end # test
