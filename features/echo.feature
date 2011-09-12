Feature: Echo
  In order to support statements i agree with
  As a user
  I want to give my echo to statements

  Scenario: Give an Echo to a statement as a user
    Given I am logged in as "user" with password "true"
      And a proposal without echos
    When I go to the proposal
      And I follow "echo_button"
    # Todo: This test will always fail. Echo link does not work without js atm
    Then I should see a "echo" button
      And the proposal should have one echo
      And the proposal should have "user test" as supporters
      #And the proposal should have "user test" as follower
    Given I go to the proposal
      And I follow "echo_button"
    Then I should see a "echo" button
      And the proposal should have no more echo
      #And the proposal should not have "user test" as follower

  Scenario: Undo an Echo to a statement as a user
    Given I am logged in as "user" with password "true"
      And I gave an echo already to a proposal
    When I go to the proposal
      And I follow "echo_button"
    # Todo: This test will always fail. Echo link does not work without js atm
    Then I should see a "echo" button
      And the proposal should have no more echo
      #And the proposal should not have "user test" as follower

  Scenario: Visit an Statement without giving an echo
    Given I am logged in as "user" with password "true"
      And a proposal without echos
    When I go to the proposal
    Then the proposal should have one visitor but no echos


  Scenario: Comprehensive integrity check for echos and user echos with multiple users
    Given I am logged in as "user" with password "true"
      And I am on the discuss index
      And I follow localized "discuss.featured_topics.title"
      And I follow "echonomyJAM"
      And I choose the first Question
      And the question has no proposals
      And I am on the discuss index
      And I follow localized "discuss.featured_topics.title"
      And I follow "echonomyJAM"
      And I choose the first Question
      And I follow localized "discuss.statements.create_proposal_link"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | proposal title |
        | statement_node_statement_attributes_statement_documents_attributes_0_text  | proposal text. |
      And I press "Save"
      And I have the "proposal title" proposal
    Then the proposal should have 1 visitors
      And the proposal should have 1 supporters
      And the proposal should have "user test" as visitors
      And the proposal should have "user test" as supporters
    Given I follow "logout_button"
      And I login as "luise" with password "luise"
      And I go to the proposal
    Then I am not supporter of the proposal
      And the proposal should have 2 visitors
      And the proposal should have 1 supporters
      And the proposal should have "user test, luise echmeier" as visitors
      And the proposal should have "user test" as supporters
    Given I follow "echo_button"
    Then I am supporter of the proposal
      And the proposal should have 2 visitors
      And the proposal should have 2 supporters
      And the proposal should have "user test, luise echmeier" as visitors
      And the proposal should have "user test, luise echmeier" as supporters
    Given I follow "echo_button"
    Then I am not supporter of the proposal
      And the proposal should have 2 visitors
      And the proposal should have 1 supporters
      And the proposal should have "user test, luise echmeier" as visitors
      And the proposal should have "user test" as supporters
    Given I follow "logout_button"
      And I login as "user" with password "true"
      And I go to the proposal
    Then I am supporter of the proposal
      And the proposal should have 2 visitors
      And the proposal should have 1 supporters
      And the proposal should have "user test, luise echmeier" as visitors
      And the proposal should have "user test" as supporters
    Given I follow "echo_button"
    Then I am not supporter of the proposal
      And the proposal should have 2 visitors
      And the proposal should have 0 supporters
      And the proposal should have "user test, luise echmeier" as visitors


  Scenario: User tries to echo an improvement without echoing the respective proposal
    Given I am logged in as "user" with password "true"
      And I am on the discuss index
      And I follow localized "discuss.featured_topics.title"
      And I follow "echonomyJAM"
      And I choose the "Test Question2?" Question
      And I choose the "A first proposal!" Proposal
      And the proposal has no supporters
      And I choose the "A better first proposal" Improvement
    Given I follow "echo_button"
    Then I am not supporter of the improvement
  #    And I should see "You can only support improvements if you support the proposal itself."
      And I go to the proposal
      And I follow "echo_button"
    Then I am supporter of the proposal
      And I go to the proposal
      And I choose the "A better first proposal" Improvement
    Given I follow "echo_button"
    Then I am supporter of the improvement
   #   And I should not see "You can only support improvements if you support the proposal itself."
      And I go to the proposal
      And I follow "echo_button"
    Then I am not supporter of the proposal
      And I am not supporter of the improvement
 #     And I should see "You can only support improvements if you support the proposal itself."

  Scenario: User echoes an improvement, and this becomes ready
    Given the minimum number of votes is 1
      And I am logged in as "joe" with password "true"
      And I am on the discuss featured
      And I follow "Featured"
      And I follow "echonomyJAM"
      And I choose the "Test Question2?" Question
      And I choose the "A first proposal!" Proposal
      And I follow "echo_button"
      And I choose the "A better fourth proposal" Improvement
      Given I follow "echo_button"
    Then I am supporter of the improvement
      And the state of the improvement must be "ready"



    #####################
    # DELETE STATEMENTS #
    #####################

  Scenario: User deletes improvement
    Given I am logged in as "admin" with password "true"
      And I am on the discuss index
    When I follow localized "discuss.featured_topics.title"
      And I follow "echonomyJAM"
      And I choose the "Test Question2?" Question
      And I choose the "A first proposal!" Proposal
      And I follow "echo_button"
      And I follow localized "discuss.statements.create_improvement_link"
      And I fill in the following:
      | statement_node_statement_attributes_statement_documents_attributes_0_title           | Main Improve   |
      | statement_node_statement_attributes_statement_documents_attributes_0_text            | improve, biatx |
      And I press "Save"
      And I go to the proposal
      And I choose the "Main Improve" Improvement
    Then I should have 3 subscriptions
      And the improvement should have a "created" event
    When I follow localized "application.general.delete"
      And I go to the proposal
    Then I should not see "Main Improve"
      #And the improvement should not have a "created" event
      And I should have 2 subscriptions

  Scenario: User deletes proposal, subsequently deleting children and all related objects
    Given I am logged in as "admin" with password "true"
      And I am on the discuss index
    When I follow localized "discuss.featured_topics.title"
      And I follow "echonomyJAM"
      And I choose the "Test Question2?" Question
      And I choose the "A first proposal!" Proposal
      And I follow "echo_button"
      And I follow localized "discuss.statements.create_improvement_link"
      And I fill in the following:
      | statement_node_statement_attributes_statement_documents_attributes_0_title           | Main Improve   |
      | statement_node_statement_attributes_statement_documents_attributes_0_text            | improve, biatx |
      And I press "Save"
      And I go to the proposal
      And I choose the "Main Improve" Improvement
    Then I should have 3 subscriptions
      And the improvement should have a "created" event
    When I go to the proposal
      And I follow localized "application.general.delete"
      And I go to the question
    Then I should not see "A first proposal!"
      #And the improvement should not have a "created" event
      And I should have 1 subscription

