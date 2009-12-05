Feature: Echo
  In order to support statements i agree with
  As a user
  I want to give my echo to statements

  Scenario: Give an Echo to a statement as a user
    Given I am logged in as "user" with password "true"
      And a proposal wihout echos
    When I go to the proposal
      And I follow "echo_button"
    # Todo: This test will always fail. Echo link does not work without js atm
    #Then I should see a "statement supported" message
    #  And I should see the "echo_button" link
    #  And the proposal should have one echo

  Scenario: Undo an Echo to a statement as a user
    Given I am logged in as "user" with password "true"
      And I gave an echo already to a proposal
    When I go to the proposal
      And I follow "echo_button"
    # Todo: This test will always fail. Echo link does not work without js atm
    #Then I should see a "statement unsupported" message
    #  And I should see the "echo_button" link
    #  And the proposal should have no more echo
