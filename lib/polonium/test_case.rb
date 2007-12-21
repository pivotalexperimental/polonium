module Polonium
  # The Test Case class that runs your Selenium tests.
  # You are able to use all methods provided by Selenium::SeleneseInterpreter with some additions.
  class TestCase < Test::Unit::TestCase
    module ClassMethods
      def subclasses
        @subclasses ||= []
      end

      def inherited(subclass)
        # keep a list of all subclasses on the fly, so we can run them all later from the Runner
        subclasses << subclass unless subclasses.include?(subclass)
        super
      end

      def all_subclasses_as_suite(configuration)
        suite = Test::Unit::TestSuite.new
        all_descendant_classes.each do |test_case_class|
          test_case_class.suite.tests.each do |test_case|
            test_case.configuration = configuration
            suite << test_case
          end
        end
        suite
      end

      def all_descendant_classes
        extract_subclasses(self)
      end

      def extract_subclasses(parent_class)
        classes = []
        parent_class.subclasses.each do |subclass|
          classes << subclass
          classes.push(*extract_subclasses(subclass))
        end
        classes
      end

      unless Object.const_defined?(:RAILS_ROOT)
        attr_accessor :use_transactional_fixtures, :use_instantiated_fixtures
      end
    end
    extend ClassMethods
    undef_method 'default_test' if instance_methods.include?('default_test')

    self.use_transactional_fixtures = false
    self.use_instantiated_fixtures  = true

    include TestUnitDsl
    def setup
      #   set "setup_once" to true
      #   to prevent fixtures from being re-loaded and data deleted from the DB.
      #   this is handy if you want to generate a DB full of sample data
      #   from the tests.  Make sure none of your selenium tests manually
      #   reset data!
      #TODO: make this configurable
      setup_once = false

      raise "Cannot use transactional fixtures if ActiveRecord concurrency is turned on (which is required for Selenium tests to work)." if self.class.use_transactional_fixtures
      unless setup_once
        ActiveRecord::Base.connection.update('SET FOREIGN_KEY_CHECKS = 0')
        super
        ActiveRecord::Base.connection.update('SET FOREIGN_KEY_CHECKS = 1')
      else
        unless InstanceMethods.const_defined?("ALREADY_SETUP_ONCE")
          super
          InstanceMethods.const_set("ALREADY_SETUP_ONCE", true)
        end
      end
      @selenium_driver = configuration.driver
    end

    def teardown
      selenium_driver.stop if should_stop_driver?
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
