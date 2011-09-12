Feature: User Generated Debates

  @ok
  Scenario: user tries to create Debate without content
    Given I am logged in as "user" with password "true"
    When I am on My Questions
      And I follow "Create a new question"
      And I press "Save"
    Then I should see "The field 'Title' must not be empty."
    Then I should see "The field 'Summary' must not be empty."

  @ok
  Scenario: user tries to create Debate without text
    Given I am logged in as "user" with password "true"
    When I am on My Questions
      And I follow "Create a new question"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | A Debate for all Seasons |
      And I press "Save"
    Then I should see "The field 'Summary' must not be empty."

  @ok
  Scenario: user tries to create Debate without title
    Given I am logged in as "user" with password "true"
    When I am on My Questions
      And I follow "Create a new question"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_text | A Debate for all Seasons |
      And I press "Save"
    Then I should see "The field 'Title' must not be empty."

  @ok
  Scenario: user creates Debate without tags, then edits it and adds a new tag
    Given I am logged in as "user" with password "true"
    When I am on My Questions
      And I follow "Create a new question"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | A Debate for all Seasons |
        | statement_node_statement_attributes_statement_documents_attributes_0_text  | A Debate for all Seasons |
      And I press "Save"
    Then I should see "A Debate for all Seasons"
    When I follow "Edit"
      And I fill in the following:
        | question_statement_attributes_statement_documents_attributes_0_text  | I wish this text was not so repetitive |
        | question_statement_attributes_topic_tags                             | first_tag |
      And I press "Save"
    Then I should see "The Question has been updated successfully."

  @ok
  Scenario: user creates Debate with multiple tags
    Given I am logged in as "user" with password "true"
    When I am on My Questions
      And I follow "Create a new question"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | A Debate for all Seasons |
        | statement_node_statement_attributes_statement_documents_attributes_0_text  | A Debate for all Seasons |
        | statement_node_statement_attributes_topic_tags                             | first_tag,second_tag,third_tag|
      And I press "Save"
    Then I should see "The new Question has been entered successfully."
    Then the question "A Debate for all Seasons" should have "first_tag, second_tag, third_tag" as tags

  @ok
  Scenario: user creates Debate with multiple tags, then deletes some
    Given I am logged in as "user" with password "true"
    When I am on My Questions
      And I follow "Create a new question"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | A Debate for all Seasons |
        | statement_node_statement_attributes_statement_documents_attributes_0_text  | A Debate for all Seasons |
        | statement_node_statement_attributes_topic_tags                             | first_tag,second_tag,third_tag|
      And I press "Save"
      And I follow "Edit"
      And I fill in the following:
        | question_statement_attributes_topic_tags                     | first_tag |
      And I press "Save"
    Then the question "A Debate for all Seasons" should have "first_tag" as tags

  @ok
  Scenario: editor creates Debate with an hash tag echonomyjam, and it should be visible in the echonomy jam listing
    Given I am logged in as "editor" with password "true"
    When I am on My Questions
      And I follow "Create a new question"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | A Debate for all Seasons |
        | statement_node_statement_attributes_statement_documents_attributes_0_text  | A Debate for all Seasons |
        | statement_node_statement_attributes_topic_tags                             | #echonomyjam |
      And I choose "Publish immediately (further editing will be limited)"
      And I press "Save"
    When I am on the discuss featured
    When I follow "Pilot Projects"
    When I follow "echonomyJAM"
      Then I should see "A Debate for all Seasons"

  @ok
  Scenario: user creates Debate, then goes to his My Questions area and should publish it successfully
    Given there are no questions
    Given I am logged in as "user" with password "true"
    When I am on My Questions
      And I follow "Create a new question"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | A Debate for all Seasons |
        | statement_node_statement_attributes_statement_documents_attributes_0_text  | A Debate for all Seasons |
        | statement_node_statement_attributes_topic_tags                             | first_tag |
      And I choose "Set up at first and publish later"
      And I press "Save"
      And I go to "My Questions"
      And I follow "Release"
    Then I should see "Released"

  @ok
  Scenario: added a hash tag to a debate when i had the asterisk tag as a decision making tag, and it should work!
    Given I am logged in as "user" with password "true"
      And I have "*xyz" as decision making tags
      And I am on My Questions
      And I follow localized "discuss.my_questions.add"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | A Debate for all Seasons |
        | statement_node_statement_attributes_statement_documents_attributes_0_text  | A Debate for all Seasons |
        | statement_node_statement_attributes_topic_tags                             | #xyz |
      And I press "Save"
    Then I should see "The new Question has been entered successfully."
    Then the question "A Debate for all Seasons" should have "#xyz" as tags

  @ok
  Scenario: An editor should define any hash tags
    Given I am logged in as "editor" with password "true"
      And I am on My Questions
      And I follow localized "discuss.my_questions.add"
      And I fill in the following:
        | statement_node_statement_attributes_statement_documents_attributes_0_title | A Debate for all Seasons |
        | statement_node_statement_attributes_statement_documents_attributes_0_text  | A Debate for all Seasons |
        | statement_node_statement_attributes_topic_tags                     | #new,#echo |
      And I press "Save"
    Then I should see "The new Question has been entered successfully."
    Then the question "A Debate for all Seasons" should have "#new,#echo" as tags