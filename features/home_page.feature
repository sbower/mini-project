Feature: Home
  When on the home page I should see the
  text Automation for the People.

  Scenario: Display home page
    Given I am on the home page
    Then I should see "Automation for the People"
