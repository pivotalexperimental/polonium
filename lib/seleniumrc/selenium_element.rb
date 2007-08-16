module Seleniumrc
  class SeleniumElement
    include WaitFor
    attr_reader :selenium, :locator

    def initialize(selenium, locator)
      @selenium = selenium
      @locator = locator
    end

    def is_present(params={})
      params = {:message => "Expected element '#{locator}' to be present, but it was not"}.merge(params)
      wait_for(params) do
        selenium.is_element_present(locator)
      end
      true
    end

    def has_value(expected_value)
      is_present
      wait_for do |context|
        actual = selenium.get_value(locator)
        context.message = "Expected '#{locator}' to be '#{expected_value}' but was '#{actual}'"
        expected_value == actual
      end
    end

    def has_attribute(expected_value)
      is_present
      wait_for do |context|
        actual = selenium.get_attribute(locator)  #todo: actual value
        context.message = "Expected attribute '#{locator}' to be '#{expected_value}' but was '#{actual}'"
        expected_value == actual
      end
    end
  end
end