configuration = Polonium::Configuration.instance
app_runner = configuration.create_server_runner
app_runner.start

at_exit do
  app_runner.stop
  passed = $! ? false : true
  configuration.stop_driver_if_necessary(passed)
end