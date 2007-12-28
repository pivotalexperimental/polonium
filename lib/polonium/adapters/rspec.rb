class Spec::Runner::Options
  attr_accessor :selenium_configuration, :selenium_app_runner

  def run_examples_with_selenium_runner(*args)
    success = run_examples_without_selenium_runner(*args)
    selenium_app_runner.stop
    selenium_configuration.stop_driver_if_necessary(success)
    success
  end
  alias_method_chain :run_examples, :selenium_runner
end

rspec_options.selenium_configuration = Polonium::Configuration.instance
rspec_options.selenium_app_runner = nil

Spec::Example::ExampleMethods.before(:all) do
  unless rspec_options.selenium_app_runner
    rspec_options.selenium_app_runner = rspec_options.selenium_configuration.create_server_runner
    rspec_options.selenium_app_runner.start
  end
end
