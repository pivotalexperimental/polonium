module Polonium
  module TestUnitDsl
    class << self
      def page_assertion(name)
        module_eval(
          "def assert_#{name}(value, params={})\n" +
          "  page.assert_#{name}(value, params)\n" +
          "end",
          __FILE__,
          __LINE__ - 4
        )
      end

      def element_assertion(name)
        module_eval(
          "def assert_#{name}(locator, *args)\n" +
          "  element(locator).assert_#{name}(*args)\n" +
          "end",
          __FILE__,
          __LINE__ - 4
        )
      end
    end

    page_assertion :title
    page_assertion :text_present
    page_assertion :text_not_present
    page_assertion :location_ends_with
    deprecate :assert_location_ends_in, :assert_location_ends_with

    element_assertion :value
    element_assertion :attribute   # yes, it's a little weird... in this case element is really an attribute
    element_assertion :selected
    element_assertion :checked
    element_assertion :not_checked
    element_assertion :text
    element_assertion :element_present
    element_assertion :element_not_present
    element_assertion :next_sibling
    element_assertion :contains_in_order
    element_assertion :visible
    element_assertion :not_visible

    # Assert and wait for locator element to contain text.
    def assert_element_contains(locator, text, options = {})
      element(locator).assert_contains(text, options)
    end

    # Assert and wait for locator element to not contain text.
    def assert_element_does_not_contain(locator, text, options={})
      element(locator).assert_does_not_contain(text, options)
    end
    deprecate :assert_element_does_not_contain_text, :assert_element_does_not_contain
    deprecate :wait_for_element_to_not_contain_text, :assert_element_does_not_contain
    deprecate :wait_for_text_in_order, :assert_contains_in_order
  end
end