module Seleniumrc
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

    # Assert and wait for locator element to contain text.
    def assert_element_contains(locator, text, options = {})
      element(locator).assert_contains(text, options)
    end

    # Assert and wait for locator element to not contain text.
    def assert_element_does_not_contain_text(locator, text, options={})
      element(locator).does_not_contain_text(text, options)
    end
    alias_method :assert_element_does_not_contain, :assert_element_does_not_contain_text
    alias_method :wait_for_element_to_not_contain_text, :assert_element_does_not_contain_text

    # Assert and wait for the element with id next sibling is the element with id expected_sibling_id.
    def assert_next_sibling(locator, expected_sibling_id, options = {})
      element(locator).has_next_sibling(expected_sibling_id, options)
    end

    # Assert and wait for locator element has text fragments in a certain order.
    def assert_text_in_order(locator, *text_fragments)
      element(locator).has_text_in_order(*text_fragments)
    end
    alias_method :wait_for_text_in_order, :assert_text_in_order

    def assert_visible(locator, options = {})
      element(locator).is_visible(options)
    end

    def assert_not_visible(locator, options = {})
      element(locator).is_not_visible(options)
    end
  end
end