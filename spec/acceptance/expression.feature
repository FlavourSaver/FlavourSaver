Feature: A basic handlebars expression

  Scenario: evaluate simple handlebars expressions
    Given a simple handlebars expression
    When I evaluate the expression
    Then I should see it's result
