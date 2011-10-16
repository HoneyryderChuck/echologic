require 'test_helper'

class StatementsControllerTest < ActionController::TestCase
  def setup
    login_as :editor
    @controller = StatementsController.new
    flexmock(SocialService.instance).should_receive(:share_activities).with(Hash, Hash).and_return({:success => ['facebook', 'twitter'], :failed => ['linkedin'], :timeout => []})
  end

  #####################
  # QUESTION MODULE #
  #####################

  test "should get discuss search" do
    get :category
    assert_response :success
  end

  test "should get discuss search with a value" do
    get :category, :search_terms => '#echonomyjam'
    assert_response :success
  end

  test "should get my questions" do
    get :my_questions
    assert_response :success
  end

  test "should publish non published debate" do
    prev_published = StatementNode.by_published(false).count
    put :publish, :id => statement_nodes(:non_published_question).to_param
    assert_equal StatementNode.by_published(false).count, prev_published+1
  end

  #####################
  # ECHOABLE MODULE   #
  #####################

  test "should echo statement node" do
    assert_difference('UserEcho.count', 1) do
      put :echo, :id => statement_nodes('first-proposal').to_param
    end
  end

  ########################
  # INCORPORATION MODULE #
  ########################

  test "should get incorporation form" do
    i = Improvement.first
    i.readify! ; i.stage! ; i.approve!
    get :incorporate, :id => statement_nodes('first-proposal').to_param, :approved_ip => i.to_param
    assert_response :success
  end


  ######################
  # TRANSLATION MODULE #
  ######################


  test "should translate the question" do
    user = users(:editor)
    document = statement_documents('test-question-doc-english')
    document.lock(user)

    assert_difference('StatementDocument.count', 1) do
      I18n.locale = 'pt'
      put :create_translation,
       :id => statement_nodes('test-question').to_param,
       :question => {
        :statement_attributes => {
          :id => statements('test-question-statement').to_param,
          :statement_documents_attributes => {
            "0" => {
              :title => "Translation in Portuguese",
              :text => "És cruel, meteste a tua filha num bordel",
              :locked_at => document.locked_at.to_s,
              :statement_history_attributes => {
                :action_id => StatementAction[:translated].id,
                :old_document_id => document.to_param
              }
            }
          },
          :editorial_state_id => StatementState[:published].id
        },
        :parent_id => nil
      }
    end
  end

  ##############################

  test "should get to view the statement" do
    get :show, :id => statement_nodes('test-question').to_param
    assert_response :success
    get :show, :id => statement_nodes('first-proposal').to_param
    assert_response :success
    get :show, :id => statement_nodes('third-impro-proposal').to_param
    assert_response :success
  end

  test "should get to view the question teaser" do
    get :add, :type => :question
    assert_response :success
  end
  test "should get to view the proposal teaser" do
    get :add, :type => :proposal, :id => statement_nodes('test-question').to_param
    assert_response :success
  end
  test "should get to view the improvement teaser" do
    get :add, :type => :improvement, :id => statement_nodes('first-proposal').to_param
    assert_response :success
  end
  test "should get to view the pro argument teaser" do
    get :add, :type => :pro_argument, :id => statement_nodes('first-proposal').to_param
    assert_response :success
  end
  test "should get to view the contra argument teaser" do
    get :add, :type => :contra_argument, :id => statement_nodes('first-proposal').to_param
    assert_response :success
  end
  test "should get to view the follow-up question teaser" do
    get :add, :type => :follow_up_question, :id => statement_nodes('first-proposal').to_param
    assert_response :success
  end
  test "should get to view the background infos teaser" do
    get :add, :type => :background_info, :id => statement_nodes('first-proposal').to_param
    assert_response :success
  end

  test "should get the new question form" do
    get :new, :type => :question
    assert_response :success
  end
  test "should get the new proposal form" do
    get :new, :id => statement_nodes('test-question').to_param, :type => :proposal
    assert_response :success
  end
  test "should get the new improvement form" do
    get :new, :id => statement_nodes('first-proposal').to_param, :type => :improvement
    assert_response :success
  end
  test "should get the new pro argument form" do
    get :new, :id => statement_nodes('first-proposal').to_param, :type => :pro_argument
    assert_response :success
  end
  test "should get the new contra argument form" do
    get :new, :id => statement_nodes('first-proposal').to_param, :type => :contra_argument
    assert_response :success
  end
  test "should get the new follow-up question form" do
    get :new, :id => statement_nodes('first-proposal').to_param, :type => :follow_up_question
    assert_response :success
  end
  test "should get the new background info form" do
    get :new, :id => statement_nodes('first-proposal').to_param, :type => :background_info
    assert_response :success
  end


  test "should create new question" do
    assert_difference('Question.count', 1) do
      post :create, :type => "question",
      :statement_node => {
        :statement_attributes  => {
          :statement_documents_attributes => {
            "0" => {
              :title => "Super Question", 
              :text => "I am Sam", 
              :language_id => Language[:en].id,
              :locked_at => "",
              :statement_history_attributes => {
                :action_id => StatementAction[:created].id
              }
            }
          },
          :editorial_state_id => StatementState[:published].id,
          :topic_tags => ""
        },
        :parent_id => nil
      }
    end
  end
  
  test "should create new question with existing statement" do
    assert_difference('Statement.count', 0) do
      post :create, :type => "question",
      :statement_node => {
        :statement_id => statements('test-question-statement').to_param,
        :statement_attributes => {
          :editorial_state_id => StatementState[:published].id,
          :statement_documents_attributes => {
            "0" => {
              :title => "Super Question", 
              :text => "I am Sam", 
              :language_id => Language[:en].id,
              :locked_at => "",
              :statement_history_attributes => {
                :action_id => StatementAction[:created].id
              }                  
            }
          },
          :topic_tags => ""
        },
        :parent_id => nil
      }
      assert_equal "Test Question?", assigns(:statement_document).title 
    end
  end

  test "shoud create proposal" do
    assert_difference('Proposal.count', 1) do
      post :create, :type => "proposal", :echo => true,
      :statement_node => {
        :statement_attributes => {
          :editorial_state_id => StatementState[:published].id,
          :statement_documents_attributes => {
            "0" => {
              :title => "Super Proposal", 
              :text => "I am Sam",
              :language_id => Language[:en].id,
              :locked_at => "",
              :statement_history_attributes => {:action_id => StatementAction[:created].id}
            }
          }
        },
        :parent_id => statement_nodes('test-question').to_param 
      }
    end
  end

  test "should create improvement" do
    assert_difference('Improvement.count', 1) do
      post :create, :type => "improvement", :echo => true,
      :statement_node => {
        :statement_attributes => {
          :editorial_state_id => StatementState[:published].id,
          :statement_documents_attributes => {
            "0" => {
              :title => "Super Improvement", 
              :text => "I am Sam", 
              :language_id => Language[:en].id,
              :locked_at => "",
              :statement_history_attributes => { :action_id => StatementAction[:created].id }
            }  
          }
        },
        :parent_id => statement_nodes('first-proposal').to_param 
      }
    end
  end
  test "should create pro argument" do
    assert_difference('ProArgument.count', 1) do
      post :create, :type => "pro_argument", :echo => true,
      :statement_node => {
        :statement_attributes => {
          :editorial_state_id => StatementState[:published].id,
          :statement_documents_attributes => {
            "0" => {
              :title => "Super Pro Argument",
              :text => "I am Sam", 
              :language_id => Language[:en].id,
              :locked_at => "",
              :statement_history_attributes => { :action_id => StatementAction[:created].id },
            }
          }
        },
        :parent_id => statement_nodes('first-proposal').to_param 
      }
    end
  end
  test "should create contra argument" do
    assert_difference('ContraArgument.count', 1) do
      post :create, :type => "contra_argument", :echo => true,
      :statement_node => {
        :statement_attributes => {
          :editorial_state_id => StatementState[:published].id,
          :statement_documents_attributes => {
            "0" => {
              :title => "Super Contra Argument",
              :text => "I am Sam", 
              :language_id => Language[:en].id,
              :locked_at => "",
              :statement_history_attributes => { :action_id => StatementAction[:created].id },
            }
          }
        },
        :parent_id => statement_nodes('first-proposal').to_param 
      }
    end
  end
  test "should create follow up question" do
    assert_difference('FollowUpQuestion.count', 1) do
      post :create, :type => "follow_up_question", :echo => true,
      :statement_node => {
        :statement_attributes => {
          :editorial_state_id => StatementState[:published].id,
          :statement_documents_attributes => {
            "0" => {
              :title => "Super Follow Up Question", 
              :text => "I am Sam", 
              :language_id => Language[:en].id,
              :locked_at => "",
              :statement_history_attributes => { :action_id => StatementAction[:created].id }
            }  
          }
        },
        :parent_id => statement_nodes('first-proposal').to_param 
      }
    end
  end
  test "should create background info" do
    assert_difference('BackgroundInfo.count', 1) do
      post :create, :type => "background_info", :echo => true,
      :statement_node => {
        :statement_attributes => {
          :editorial_state_id => StatementState[:published].id,
          :info_code => InfoType[:video].code,
          :external_url_attributes => {:info_url => "http://thevideourl.com"},
          :statement_documents_attributes => {
            "0" => {
              :title => "Super Background Info", 
              :text => "I am Sam", 
              :language_id => Language[:en].id,
              :locked_at => "",
              :statement_history_attributes => {:action_id => StatementAction[:created].id , }
            }
          }
        },
        :parent_id => statement_nodes('first-proposal').to_param
      }
    end
  end

  test "should get the edit question form" do
    get :edit, :id => statement_nodes('test-question').to_param, :type => :question, :current_document_id => statement_documents('test-question-doc-english').to_param
    assert_response :success
    assert_nil assigns(:info)
  end
  test "should get the edit proposal form" do
    get :edit, :id => statement_nodes('first-proposal').to_param, :type => :proposal, :current_document_id => statement_documents('first-proposal-doc-english').to_param
    assert_response :success
    assert_nil assigns(:info)
  end
  test "should get the edit improvement form" do
    get :edit, :id => statement_nodes('third-impro-proposal').to_param, :type => :improvement, :current_document_id => statement_documents('third-impro-proposal-doc-english').to_param
    assert_response :success
    assert_nil assigns(:info)
  end
  test "should not get the edit proposal form cuz somebody just updated it" do
    login_as :user
    statement_nodes('first-proposal').supported! users(:ben)
    get :edit, :id => statement_nodes('first-proposal').to_param, :type => :proposal, :current_document_id => statement_documents('first-proposal-doc-english').to_param
    assert_response :success
    assert_equal I18n.t('discuss.statements.cannot_be_edited'), assigns(:info)
  end
  test "should not get the edit question form" do
    get :edit, :id => statement_nodes('test-question').to_param, :type => :question, :current_document_id => 0
    assert_template 'statements/show'
    assert_response :success
    assert_equal I18n.t('discuss.statements.statement_updated', :type => 'Question'), assigns(:info)
  end



  test "should get more proposal children" do
    get :more, :id => statement_nodes('test-question').to_param, :type => "proposal"
    assert_kind_of Hash, assigns(:children)
    assert_not_nil assigns(:children)
    assert_equal 7, assigns(:children)[:Proposal].size
    assert_response :success
  end

  test "should get more argument children" do
    get :more, :id => statement_nodes('first-proposal').to_param, :type => "argument"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 2, assigns(:children)[:Argument].size # Should be an array with 2 arrays inside, and they must be empty both
    assert assigns(:children)[:Argument].select{|s|s.kind_of? Array and s.empty?}
    assert_response :success
  end

  test "should get more follow up question children" do
    get :more, :id => statement_nodes('test-question').to_param, :type => "follow_up_question"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 0, assigns(:children)[:FollowUpQuestion].size # no follow up questions
    assert_response :success
  end



  test "should get proposal children" do
    get :children, :id => statement_nodes('test-question').to_param, :type => "proposal"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 7, assigns(:children)[:Proposal].size
    assert_response :success
  end

  test "should get argument children" do
    get :children, :id => statement_nodes('first-proposal').to_param, :type => "argument"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 2, assigns(:children)[:Argument].size
    assert assigns(:children)[:Argument].select{|s|s.kind_of? Array and s.empty?}
    assert_response :success
  end

  test "should get follow up question children" do
    get :children, :id => statement_nodes('test-question').to_param, :type => "follow_up_question"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 0, assigns(:children)[:FollowUpQuestion].size
    assert_response :success
  end

  test "should get test question siblings coming from discuss search" do
    get :descendants, :type => "question", :current_node => statement_nodes('test-question').to_param, :origin => "ds|1"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 7, assigns(:children)[:Question].size
    assert_response :success
  end

  test "should get test question siblings coming from discuss search with search term test" do
    get :descendants, :type => "question", :current_node => statement_nodes('test-question').to_param, :origin => "srtest|1"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 2, assigns(:children)[:Question].size
    assert_response :success
  end

  test "should get test question siblings being test question a follow up question from test question 2" do
    get :descendants, :type => "question", :current_node => statement_nodes('test-question').to_param, :origin => "fq#{statement_nodes('test-question-2').to_param}"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 0, assigns(:children)[:Question].size
    assert_response :success
  end

  test "should get second proposal siblings" do
    get :descendants, :id => statement_nodes('test-question').to_param, :type => "proposal", :current_node => statement_nodes('second-proposal').to_param
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 9, assigns(:children)[:Proposal].size
    assert_response :success
  end

  test "should get argument siblings" do
    get :descendants, :id => statement_nodes('second-proposal').to_param, :type => "argument"
    assert_not_nil assigns(:children)
    assert_kind_of Hash, assigns(:children)
    assert_equal 2, assigns(:children)[:Argument].size
    assert assigns(:children)[:Argument].select{|s|s.kind_of? Array and s.empty?}
    assert_response :success
  end

  test "should get the statement node authors" do
    @statement_node = Question.first
    get :authors,:id => @statement_node.id
    assert_not_nil assigns(:authors)
    assert_equal @statement_node.authors.size, assigns(:authors).size
    assert_response :success
  end


  test "should get me the right parents list" do
    get :ancestors, :id => statement_nodes('first-impro-proposal').to_param
    assert assigns(:statement_ids).include?(statement_nodes('test-question-2').to_param.to_i)
    assert assigns(:statement_ids).include?(statement_nodes('first-proposal').to_param.to_i)
    assert_response :success
  end


  ########################
  # SOCIAL SHARING TESTS #
  ########################

  test "should not get social widget bcuz im not a supporter of this statement" do
    get :social_widget, :id => statement_nodes('test-question').to_param
    assert_equal I18n.t("discuss.statements.supporter_to_share"), assigns(:info)
    assert_response :success
  end

  test "should get social widget" do
    statement_nodes('test-question').supported!(users(:editor))
    get :social_widget, :id => statement_nodes('test-question').to_param
    assert assigns(:proposed_url).include?("http://#{ECHO_HOST}/test-question")
    assert assigns(:proposed_url).include?(tags('echonomy-jam').value)
    assert_response :success
  end

  test "should get social widget and message must have the hash tag of root" do
    statement_nodes('second-proposal').supported!(users(:editor))
    get :social_widget, :id => statement_nodes('second-proposal').to_param
    assert assigns(:proposed_url).include?("http://#{ECHO_HOST}/second-proposal")
    assert assigns(:proposed_url).include?(tags('echonomy-jam').value)
    assert_response :success
  end

  test "should not share bcuz i'm not a supporter of this statement" do
    assert_difference('ShortcutUrl.count', 0) do
      post :share, {:id => statement_nodes('test-question').to_param,
                    :providers => {'facebook' => 'enabled', 'twitter' => 'enabled'},
                    :text => "i would like to make an echo"
                    }
      assert_nil assigns(:shortcut_url)
      assert_equal I18n.t("discuss.statements.supporter_to_share"), assigns(:info)
    end
  end

  test "should share message to twitter and facebook account" do
    statement_nodes('test-question').supported!(users(:editor))
    assert_difference('ShortcutUrl.count', 1) do
      post :share, {:id => statement_nodes('test-question').to_param,
                    :providers => {'facebook' => 'enabled', 'twitter' => 'enabled'},
                    :text => "i would like to make an echo"
                    }
      assert_not_nil assigns(:shortcut_url)
      assert_equal "test-question", assigns(:shortcut_url).shortcut
      assert assigns(:providers_status)[:success].include?('facebook')
      assert assigns(:providers_status)[:success].include?('twitter')
    end
  end

  test "should share message to twitter and facebook account, but fail to share to linkedin" do
    statement_nodes('test-question').supported!(users(:editor))
    assert_difference('ShortcutUrl.count', 1) do
      post :share, {:id => statement_nodes('test-question').to_param,
                    :providers => {'facebook' => 'enabled', 'twitter' => 'enabled', 'linkedin' => 'enabled'},
                    :text => "i would like to make an echo"
                    }
      assert_not_nil assigns(:shortcut_url)
      assert_equal "test-question", assigns(:shortcut_url).shortcut
      assert assigns(:providers_status)[:success].include?('facebook')
      assert assigns(:providers_status)[:success].include?('twitter')
      assert assigns(:providers_status)[:failed].include?('linkedin')
    end
  end

end
