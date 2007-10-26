class Test::Unit::UI::TestRunnerMediator
  alias_method :initialize_without_seleniumrc, :initialize
  def initialize_with_seleniumrc(suite)
    initialize_without_seleniumrc(suite)
    add_listener(TestCase::STARTED, &method(:start_app_server))
    add_listener(TestCase::FINISHED, &method(:stop_app_server))
  end
  alias_method :initialize, :initialize_with_seleniumrc

  protected
  def start_app_server
    @app_runner = Seleniumrc::SeleniumConfiguration.instance.create_server_runner
    @app_runner.start
  end

  def stop_app_server
    @app_runner.stop
  end
end