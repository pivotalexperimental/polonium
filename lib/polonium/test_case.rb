module Polonium
  # The Test Case class that runs your Selenium tests.
  # You are able to use all methods provided by Selenium::SeleneseInterpreter with some additions.
  class TestCase < defined?(ActiveSupport::TestCase) ? ActiveSupport::TestCase : Test::Unit::TestCase
    class << self
      unless Object.const_defined?(:RAILS_ROOT)
        attr_accessor :use_transactional_fixtures, :use_instantiated_fixtures
      end
    end
    undef_method 'default_test' if instance_methods.include?('default_test')

    self.use_transactional_fixtures = false
    self.use_instantiated_fixtures  = true

    include SeleniumDsl
    def setup
      raise "Cannot use transactional fixtures if ActiveRecord concurrency is turned on (which is required for Selenium tests to work)." if self.class.use_transactional_fixtures
      @selenium_driver = configuration.driver
    end

    def teardown
      selenium_driver.stop if stop_driver?
      super
      if @beginning
        duration = (time_class.now - @beginning).to_f
        puts "#{duration} seconds"
      end
    end

    def selenium_test_case
      @selenium_test_case ||= TestCase
    end

    def run(result, &block)
      return if @method_name.nil? || @method_name.to_sym == :default_test
      super
    end
  end
end

TestCase = Polonium::TestCase
