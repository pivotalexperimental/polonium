class Test::Unit::UI::TestRunnerMediator
  def run_suite_with_seleniumrc
    start_app_server
    result = run_suite_without_seleniumrc
    stop_app_server(result)
    result
  end
  alias_method :run_suite_without_seleniumrc, :run_suite
  alias_method :run_suite, :run_suite_with_seleniumrc

  protected
  def start_app_server
    @selenium_driver = Polonium::Configuration.instance
    @app_runner = @selenium_driver.create_server_runner
    @app_runner.start
  end

  def stop_app_server(result)
    @app_runner.stop
    @selenium_driver.stop_driver_if_necessary(result.passed?)
  end
end