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

    def has_text_in_order(*text_fragments)
      is_present
      wait_for do |context|
        success = false
        container = selenium.get_text(locator)

        fragments_not_found = []
        fragments_out_of_order = []

        text_fragments.inject([-1, nil]) do |old_results, new_fragment|
          old_index = old_results[0]
          old_fragment = old_results[1]
          new_index = container.index(new_fragment)

          unless new_index
            fragments_not_found << "Fragment #{new_fragment} was not found\n"
          end

          if new_index && new_index < old_index
            message = "Fragment #{new_fragment} out of order:\n" <<
                      "\texpected '#{old_fragment}'\n" <<
                      "\tto come before '#{new_fragment}'\n"
            fragments_out_of_order << message
          end

          [new_index, new_fragment]
        end

        if !fragments_not_found.empty?
          context.message = "Certain fragments weren't found:\n" <<
                            "#{fragments_not_found.join("\n")}\n" <<
                            "\nhtml follows:\n #{container}\n"
        elsif !fragments_out_of_order.empty?
          context.message = "Certain fragments were out of order:\n" <<
                            "#{fragments_out_of_order.join("\n")}\n" <<
                            "\nhtml follows:\n #{container}\n"
        else
          success = true
        end

        success
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