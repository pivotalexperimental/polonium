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
    end

    def is_not_present(params={})
      params = {:message => "Expected element '#{locator}' to be absent, but it was not"}.merge(params)
      wait_for(:message => params[:message]) do
        !selenium.is_element_present(locator)
      end
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

    def has_selected(expected_value)
      is_present
      wait_for do |context|
        actual = selenium.get_selected_label(locator)
        context.message = "Expected '#{locator}' to be selected with '#{expected_value}' but was '#{actual}"
        expected_value == actual
      end
    end

    def is_checked
      is_present
      wait_for(:message => "Expected '#{locator}' to be checked") do
        selenium.is_checked(locator)
      end
    end

    def is_not_checked
      is_present
      wait_for(:message => "Expected '#{locator}' to be checked") do
        !selenium.is_checked(locator)
      end
    end

    def has_text(expected_text, options={})
      is_present
      wait_for(options) do |context|
        actual = selenium.get_text(locator)
        context.message = "Expected text '#{expected_text}' to be full contents of #{locator} but was '#{actual}')"
        expected_text == actual
      end
    end

    def contains_text(expected_text, options={})
      is_present
      options = {
        :message => "#{locator} should contain #{expected_text}"
      }.merge(options)
      wait_for(options) do
        inner_html.include?(expected_text)
      end
    end

    def does_not_contain_text(expected_text, options={})
      is_present
      wait_for(options) do
        !inner_html.include?(expected_text)
      end
    end

    def has_next_sibling(expected_sibling_id, options = {})
      is_present
      eval_js = "this.page().findElement('#{locator}').nextSibling.id"
      wait_for(:message => "id '#{locator}' should be next to '#{expected_sibling_id}'") do
        actual_sibling_id = selenium.get_eval(eval_js)
        expected_sibling_id == actual_sibling_id
      end
    end

    def inner_html
      selenium.get_eval("this.page().findElement(\"#{locator}\").innerHTML")
    end

    def ==(other)
      return false unless other.is_a?(SeleniumElement)
      return false unless self.selenium == other.selenium
      return false unless self.locator == other.locator
      true
    end
  end
end