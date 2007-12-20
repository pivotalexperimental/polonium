module Seleniumrc
  module TestUnitDsl
    class << self
      def page_assert(thing)
        module_eval("def assert_#{thing}(value, params={})\n" +
          "page.assert_#{thing}(value, params)\n" +
          "end",
          __FILE__,
          __LINE__ - 3
        )
      end
    end

    page_assert :title
    page_assert :text_present
    page_assert :text_not_present
    page_assert :location_ends_with
    deprecate :assert_location_ends_in, :assert_location_ends_with

    # Assert and wait for the locator element to have value.
    def assert_value(locator, value)
      element(locator).has_value(value)
    end

    # Assert and wait for the locator attribute to have a value.
    def assert_attribute(locator, value)
      element(locator).has_attribute(value)
    end

    # Assert and wait for locator select element to have value option selected.
    def assert_selected(locator, value)
      element(locator).has_selected(value)
    end

    # Assert and wait for locator check box to be checked.
    def assert_checked(locator)
      element(locator).is_checked
    end

    # Assert and wait for locator check box to not be checked.
    def assert_not_checked(locator)
      element(locator).is_not_checked
    end

    # Assert and wait for locator element to have text equal to passed in text.
    def assert_text(locator, text, options={})
      element(locator).has_text(text, options)
    end

    # Assert and wait for locator element to be present.
    def assert_element_present(locator, params = {})
      element(locator).is_present(params)
    end

    # Assert and wait for locator element to not be present.
    def assert_element_not_present(locator, params = {})
      element(locator).is_not_present(params)
    end

    # Assert and wait for locator element to contain text.
    def assert_element_contains(locator, text, options = {})
      element(locator).contains_text(text, options)
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