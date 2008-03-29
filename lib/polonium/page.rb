module Polonium
  class Page
    include WaitFor, ValuesMatch
    attr_reader :driver
    PAGE_LOADED_COMMAND = <<-JS
      (function(selenium) {
        BrowserBot.prototype.bodyText = function() {
            if (!this.getDocument().body) {
                return "";
            }
            return getText(this.getDocument().body);
        };
        selenium.browserbot.bodyText = BrowserBot.prototype.bodyText;
        return selenium.browserbot.getDocument().body ? true : false;
      })(this);
    JS

    def initialize(driver)
      @driver = driver
    end

    def open(url)
      driver.open(url)
    end
    alias_method :open_and_wait, :open

    def assert_title(expected_title, params = {})
      wait_for(params) do |configuration|
        actual_title = title
        configuration.message = "Expected title '#{expected_title}' but was '#{actual_title}'"
        values_match?(actual_title, expected_title)
      end
    end
    def title
      driver.get_title
    end

    def assert_text_present(expected_text, options = {})
      options = {
        :message => "Expected '#{expected_text}' to be present, but it wasn't"
      }.merge(options)
      wait_for(options) do
        is_text_present? expected_text
      end
    end
    def is_text_present?(expected_text)
      if expected_text.is_a?(Regexp)
        text_finder = "regexp:#{expected_text.source}"
      else
        text_finder = expected_text
      end
      page_loaded? && driver.is_text_present(text_finder)
    end

    def assert_text_not_present(unexpected_text, options = {})
      options = {
        :message => "Expected '#{unexpected_text}' to be absent, but it wasn't"
      }.merge(options)
      wait_for(options) do
        is_text_not_present? unexpected_text
      end
    end
    def is_text_not_present?(unexpected_text)
      if unexpected_text.is_a?(Regexp)
        text_finder = "regexp:#{unexpected_text.source}"
      else
        text_finder = unexpected_text
      end
      page_loaded? && !driver.is_text_present(text_finder)
    end

    def page_loaded?
      driver.get_eval(PAGE_LOADED_COMMAND) == true.to_s
    end

    def assert_location_ends_with(ends_with, options  ={})
      options = {
        :message => "Expected '#{driver.get_location}' to end with '#{ends_with}'"
      }.merge(options)
      wait_for(options) do
        location_ends_with? ends_with
      end
    end
    def location_ends_with?(ends_with)
      if driver.get_location =~ Regexp.new("#{Regexp.escape(ends_with)}$")
        true
      else
        false
      end
    end

    def ==(other)
      return false unless other.is_a?(Page)
      self.driver == other.driver
    end

    def method_missing(method_name, *args, &blk)
      if driver.respond_to?(method_name)
        driver.__send__(method_name, *args, &blk)
      else
        super
      end
    end
  end
end
