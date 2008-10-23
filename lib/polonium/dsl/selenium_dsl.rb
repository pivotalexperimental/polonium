module Polonium
  module SeleniumDsl
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
    polonium_deprecate :assert_location_ends_in, :assert_location_ends_with

    element_assertion :value
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

    def assert_attribute(element_locator, attribute_name, expected_value)
      element(element_locator).assert_attribute(attribute_name, expected_value)
    end

    # Assert and wait for locator element to contain text.
    def assert_element_contains(locator, text, options = {})
      element(locator).assert_contains(text, options)
    end
    alias_method :assert_element_contains_text, :assert_element_contains
    
    # Assert and wait for locator element to not contain text.
    def assert_element_does_not_contain(locator, text, options={})
      element(locator).assert_does_not_contain(text, options)
    end
    polonium_deprecate :assert_element_does_not_contain_text, :assert_element_does_not_contain

    # Does the element at locator contain the text?
    def element_contains_text(locator, text)
      element(locator).assert_contains(text)
    end

    attr_accessor :selenium_driver  
    include WaitFor

    # Download a file from the Application Server
    def download(path)
      uri = URI.parse(configuration.browser_url + path)
      puts "downloading #{uri.to_s}"
      Net::HTTP.get(uri)
    end

    def configuration
      Polonium::Configuration.instance
    end

    protected
    def method_missing(method_name, *args, &block)
      if selenium_driver.respond_to?(method_name)
        selenium_driver.__send__(method_name, *args, &block)
      else
        super
      end
    end
    delegate :open,
             :type,
             :to => :selenium_driver

    def stop_driver?
      return false unless configuration.test_browser_mode?
      configuration.stop_driver?(passed?)
    end
  end
end