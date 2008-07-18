class Spec::Runner::Options
  def stop_selenium(success)
    Polonium::Configuration.instance.app_server_runner.stop
    Polonium::Configuration.instance.stop_driver_if_necessary(success)
    success
  end

  if instance_methods.include?('after_suite_parts')
    Spec::Example::ExampleGroup.after(:suite) do |success|
      rspec_options.stop_selenium success
    end
  else
    def run_examples_with_selenium_runner(*args)
      success = run_examples_without_selenium_runner(*args)
      stop_selenium success
      success
    end
    alias_method_chain :run_examples, :selenium_runner
  end
end

Spec::Example::ExampleMethods.before(:all) do
  unless Polonium::Configuration.instance.app_server_runner
    app_server_runner = Polonium::Configuration.instance.create_app_server_runner
    app_server_runner.start
  end
end
