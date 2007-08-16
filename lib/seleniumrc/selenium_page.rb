module Seleniumrc
  class SeleniumPage
    include WaitFor
    attr_reader :selenium

    def initialize(selenium)
      @selenium = selenium
    end

    def has_title(expected_title, params = {})
      wait_for(params) do |context|
        actual_title = selenium.get_title
        context.message = "Expected title '#{expected_title}' but was '#{actual_title}'"
        has_title? expected_title, actual_title
      end
    end
    def has_title?(expected_title, actual_title=selenium.get_title)
      expected_title == actual_title
    end

    def is_text_present(pattern, options = {})
      message = options[:message] || "Expected '#{pattern}' to be present, but it wasn't"
      wait_for({:message => message}.merge(options)) do
        selenium.is_text_present(pattern)
      end
    end

    def is_text_not_present(pattern, options = {})
      message = options[:message] || "Expected '#{pattern}' to be absent, but it wasn't"
      wait_for({:message => message}.merge(options)) do
        !selenium.is_text_present(pattern)
      end
    end

    def url_ends_with(ends_with, options={})
      options = {
        :message => "Expected '#{selenium.get_location}' to end with '#{ends_with}'"
      }.merge(options)
      wait_for(options) do
        selenium.get_location =~ Regexp.new("#{Regexp.escape(ends_with)}$")
      end
    end

    def ==(other)
      return false unless other.is_a?(SeleniumPage)
      self.selenium == other.selenium
    end
  end
end