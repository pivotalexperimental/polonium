module Polonium
  class Element
    include WaitFor, ValuesMatch
    attr_reader :driver, :locator

    def initialize(driver, locator)
      @driver = driver
      @locator = locator
    end

    def assert_element_present(params={})
      driver.assert_element_present(locator, params)
    end

    def assert_element_not_present(params={})
      driver.assert_element_not_present(locator, params)
    end

    def assert_value(expected_value)
      assert_element_present
      wait_for do |configuration|
        actual_value = driver.get_value(locator)
        configuration.message = "Expected '#{locator}' to be '#{expected_value}' but was '#{actual_value}'"
        has_value? expected_value, actual_value
      end
    end

    def assert_attribute(expected_name, expected_value)
      assert_element_present
      attr_locator = "#{locator}@#{expected_name}"
      wait_for do |configuration|
        actual = driver.get_attribute(attr_locator)  #todo: actual value
        configuration.message = "Expected attribute '#{attr_locator}' to be '#{expected_value}' but was '#{actual}'"
        values_match? actual, expected_value
      end
    end

    def assert_attribute_does_not_contain(attribute_name, illegal_value)
      assert_element_present
      attr_locator = "#{locator}@#{attribute_name}"
      wait_for do |configuration|
        actual = driver.get_attribute(attr_locator)  #todo: actual value
        configuration.message = "Expected attribute '#{attr_locator}' to not contain '#{illegal_value}' but was '#{actual}'"
        !actual.match(illegal_value)
      end
    end

    def assert_selected(expected_value)
      assert_element_present
      wait_for do |configuration|
        actual = driver.get_selected_label(locator)
        configuration.message = "Expected '#{locator}' to be selected with '#{expected_value}' but was '#{actual}"
        values_match? actual, expected_value
      end
    end

    def assert_visible(options={})
      assert_element_present
      options = {
        :message => "Expected '#{locator}' to be visible, but it wasn't"
      }.merge(options)
      wait_for(options) do
        driver.is_visible(locator)
      end
    end

    def assert_not_visible(options={})
      assert_element_present
      options = {
        :message => "Expected '#{locator}' to be hidden, but it wasn't"
      }.merge(options)
      wait_for(options) do
        !driver.is_visible(locator)
      end
    end

    def assert_checked
      assert_element_present
      wait_for(:message => "Expected '#{locator}' to be checked") do
        driver.is_checked(locator)
      end
    end

    def assert_not_checked
      assert_element_present
      wait_for(:message => "Expected '#{locator}' to not be checked") do
        !driver.is_checked(locator)
      end
    end

    def assert_text(expected_text, options={})
      assert_element_present
      wait_for(options) do |configuration|
        actual = driver.get_text(locator)
        configuration.message = "Expected text '#{expected_text}' to be full contents of #{locator} but was '#{actual}')"
        values_match? actual, expected_text
      end
    end

    def assert_contains(expected_text, options={})
      return assert_contains_in_order(*expected_text) if expected_text.is_a? Array
      assert_element_present
      options = {
        :message => "#{locator} should contain #{expected_text}"
      }.merge(options)
      wait_for(options) do
        contains?(expected_text)
      end
    end

    def assert_does_not_contain(expected_text, options={})
      assert_element_present
      wait_for(options) do
        !contains?(expected_text)
      end
    end

    def assert_next_sibling(expected_sibling_id, options = {})
      assert_element_present
      eval_js = "this.page().findElement('#{locator}').nextSibling.id"
      wait_for(:message => "id '#{locator}' should be next to '#{expected_sibling_id}'") do
        actual_sibling_id = driver.get_eval(eval_js)
        expected_sibling_id == actual_sibling_id
      end
    end

    def assert_contains_in_order(*text_fragments)
      assert_element_present
      wait_for do |configuration|
        success = false

        html = driver.get_text(locator)
        results = find_text_order_error_fragments(html, text_fragments)
        fragments_not_found = results[:fragments_not_found]
        fragments_out_of_order = results[:fragments_out_of_order]

        if !fragments_not_found.empty?
          configuration.message = "Certain fragments weren't found:\n" <<
                            "#{fragments_not_found.join("\n")}\n" <<
                            "\nhtml follows:\n #{html}\n"
        elsif !fragments_out_of_order.empty?
          configuration.message = "Certain fragments were out of order:\n" <<
                            "#{fragments_out_of_order.join("\n")}\n" <<
                            "\nhtml follows:\n #{html}\n"
        else
          success = true
        end

        success
      end
    end
    
    def assert_number_of_children(expected_number)
      assert_element_present
      eval_js = "this.page().findElement('#{locator}').childNodes.length"
      wait_for(:message => "id '#{locator}' should contain exactly #{expected_number} children") do
        actual_number = driver.get_eval(eval_js)
        expected_number == actual_number.to_i
      end
    end

    def click
      driver.click locator
    end

    def type(text)
      driver.type(locator, text)
    end

    def select(option_locator)
      driver.select(locator, option_locator)
    end

    def is_present?
      driver.is_element_present(locator)
    end

    def is_not_present?
      !driver.is_element_present(locator)
    end

    def has_value?(expected_value, actual_value=driver.get_value(locator))
      expected_value == actual_value
    end

    def inner_html
      driver.get_inner_html(locator)
    end

    def contains?(text)
      inner_html.match(text) ? true : false
    end

    def ==(other)
      return false unless other.is_a?(Element)
      return false unless self.driver == other.driver
      return false unless self.locator == other.locator
      true
    end

    protected
    def method_missing(method_name, *args, &blk)
      if driver.respond_to?(method_name)
        driver_args = [locator] + args
        driver.__send__(method_name, *driver_args, &blk)
      else
        super
      end
    end

    def find_text_order_error_fragments(html, text_fragments)
      fragments_not_found = []
      fragments_out_of_order = []

      previous_index = -1
      previous_fragment = ''
      text_fragments.each do |current_fragment|
        current_index = html.index(current_fragment)
        if current_index
          if current_index < previous_index
            message = "Fragment #{current_fragment} out of order:\n" <<
                    "\texpected '#{previous_fragment}'\n" <<
                    "\tto come before '#{current_fragment}'\n"
            fragments_out_of_order << message
          end
        else
          fragments_not_found << "Fragment #{current_fragment} was not found\n"
        end
        previous_index = current_index
        previous_fragment = current_fragment
      end
      {
        :fragments_not_found => fragments_not_found,
        :fragments_out_of_order => fragments_out_of_order
      }
    end
  end
end
