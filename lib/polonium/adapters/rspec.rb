module Polonium::Adapters
  class Rspec
    class << self
      def stop_selenium(success)
        configuration.app_server_runner.stop if configuration.app_server_runner
        configuration.stop_driver_if_necessary(success)
        success
      end

      protected
      def configuration
        Polonium::Configuration.instance
      end
    end
  end
end

class Spec::Runner::Options
  if instance_methods.include?('after_suite_parts')
    Spec::Example::ExampleGroup.after(:suite) do |success|
      Polonium::Adapters::Rspec.stop_selenium success
    end
  else
    def run_examples_with_selenium_runner(*args)
      success = run_examples_without_selenium_runner(*args)
      Polonium::Adapters::Rspec.stop_selenium success
      success
    end
    alias_method_chain :run_examples, :selenium_runner
  end
end

Spec::Runner.configuration.before do
  unless Polonium::Configuration.instance.app_server_runner
    app_server_runner = Polonium::Configuration.instance.create_app_server_runner
    app_server_runner.start
  end
end
