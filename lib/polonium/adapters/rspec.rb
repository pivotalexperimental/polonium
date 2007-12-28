selenium_configuration = Polonium::Configuration.instance
selenium_app_runner = nil

Spec::Example::ExampleMethods.before(:all) do
  unless selenium_app_runner
    selenium_app_runner = selenium_configuration.create_server_runner
    selenium_app_runner.start
  end
end

Spec.after_suite do |passed|
  selenium_app_runner.stop
  selenium_configuration.stop_driver_if_necessary(passed)
end
