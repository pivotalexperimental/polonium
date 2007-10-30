module Seleniumrc
  class SeleniumPage
    include WaitFor
    attr_reader :driver
    PAGE_LOADED_COMMAND = "this.browserbot.getDocument().body ? true : false"

    def initialize(driver)
      @driver = driver
    end

    def open(url)
      driver.open(url)
    end
    alias_method :open_and_wait, :open

    def has_title(expected_title, params = {})
      wait_for(params) do |context|
        actual_title = driver.get_title
        context.message = "Expected title '#{expected_title}' but was '#{actual_title}'"
        has_title? expected_title, actual_title
      end
    end
    def has_title?(expected_title, actual_title=driver.get_title)
      expected_title == actual_title
    end

    def is_text_present(expected_text, options = {})
      options = {
        :message => "Expected '#{expected_text}' to be present, but it wasn't"
      }.merge(options)
      wait_for(options) do
        is_text_present? expected_text
      end
    end
    def is_text_present?(expected_text)
      page_loaded? && driver.is_text_present(expected_text)
    end

    def is_text_not_present(unexpected_text, options = {})
      options = {
        :message => "Expected '#{unexpected_text}' to be absent, but it wasn't"
      }.merge(options)
      wait_for(options) do
        is_text_not_present? unexpected_text
      end
    end
    def is_text_not_present?(unexpected_text)
      page_loaded? && !driver.is_text_present(unexpected_text)
    end

    def page_loaded?
      driver.get_eval(PAGE_LOADED_COMMAND) == true.to_s
    end

    def url_ends_with(ends_with, options={})
      options = {
        :message => "Expected '#{driver.get_location}' to end with '#{ends_with}'"
      }.merge(options)
      wait_for(options) do
        url_ends_with? ends_with
      end
    end
    def url_ends_with?(ends_with)
      if driver.get_location =~ Regexp.new("#{Regexp.escape(ends_with)}$")
        true
      else
        false
      end
    end

    def ==(other)
      return false unless other.is_a?(SeleniumPage)
      self.driver == other.driver
    end
  end
end