require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
context SeleniumConfiguration do
  setup do
    Seleniumrc::SeleniumConfiguration.instance_eval {@context = nil}
    @configuration = Seleniumrc::SeleniumConfiguration.instance
    @context = @configuration
  end

  specify "establish_environment__webrick_host" do
    should_establish_environment( 'internal_app_server_host', '192.168.10.1', :internal_app_server_host )
  end

  specify "establish_environment__webrick_port" do
    should_establish_environment( 'internal_app_server_port', 1337, :internal_app_server_port )
  end

  specify "establish_environment__internal_app_server_port" do
    should_establish_environment( 'external_app_server_port', 1337, :external_app_server_port )
  end

  specify "establish_environment__internal_app_server_host" do
    should_establish_environment( 'external_app_server_host', 'sammich.com', :external_app_server_host)
  end

  specify "establish_environment__selenium_server_host" do
    should_establish_environment( 'selenium_server_host', 'sammich.com')
  end

  specify "establish_environment__selenium_server_host" do
    should_establish_environment( 'selenium_server_port', 1337)
  end

  specify "establish_environment__app_server_engine" do
    should_establish_environment( 'app_server_engine', :webrick, :app_server_engine)
  end

  specify "establish_environment__browsers" do
    @context.env = stub_env
    env_var = "browsers"
    expected_value = 'konqueror'
    stub_env[env_var] = expected_value
    Seleniumrc::SeleniumConfiguration.send :establish_environment
    @configuration.browsers.should == [expected_value]
  end

  specify "establish_environment__keep_browser_open_on_failure" do
    @context.env = stub_env
    env_var = 'keep_browser_open_on_failure'
    stub_env[env_var] = 'false'
    Seleniumrc::SeleniumConfiguration.send :establish_environment
    @configuration.send(env_var).should == false
    @configuration.send(env_var).should == false

    stub_env[env_var] = 'true'
    Seleniumrc::SeleniumConfiguration.send :establish_environment
    @configuration.send(env_var).should == true
    @configuration.send(env_var).should == true

    stub_env[env_var] = 'blah'
    Seleniumrc::SeleniumConfiguration.send :establish_environment
    @configuration.send(env_var).should == true
    @configuration.send(env_var).should == true
  end

  specify "establish_environment__verify_remote_app_server_is_running" do
    @context.env = stub_env
    env_var = 'verify_remote_app_server_is_running'
    stub_env[env_var] = 'false'
    Seleniumrc::SeleniumConfiguration.send :establish_environment
    @configuration.send(env_var).should == false
    @configuration.send(env_var).should == false

    stub_env[env_var] = 'true'
    Seleniumrc::SeleniumConfiguration.send :establish_environment
    @configuration.send(env_var).should == true
    @configuration.send(env_var).should == true

    stub_env[env_var] = 'blah'
    Seleniumrc::SeleniumConfiguration.send :establish_environment
    @configuration.send(env_var).should == true
    @configuration.send(env_var).should == true
  end

  specify "internal_app_server_host" do
    should_lazily_load @configuration, :internal_app_server_host, "0.0.0.0"
  end

  specify "internal_app_server_port" do
    should_lazily_load @configuration, :internal_app_server_port, 4000
  end

  specify "external_app_server_host" do
    should_lazily_load @configuration, :external_app_server_host, "localhost"
  end

  specify "external_app_server_port" do
    should_lazily_load @configuration, :external_app_server_port, 4000
  end

  specify "browsers__lazy_loaded" do
    should_lazily_load @configuration, :browsers, [Seleniumrc::SeleniumConfiguration::FIREFOX]
  end

  specify "keep_browser_open_on_failure" do
    should_lazily_load @configuration, :keep_browser_open_on_failure, true
  end

  specify "formatted_browser" do
    @configuration.current_browser = Seleniumrc::SeleniumConfiguration::IEXPLORE
    @configuration.formatted_browser.should == "*iexplore"
  end

  specify "browser_url" do
    @configuration.external_app_server_host = "test.com"
    @configuration.external_app_server_port = 101
    @configuration.browser_url.should == "http://test.com:101"
  end

  specify "run_each_browser_within_the_browsers" do
    expected_browsers = ["iexplore", "firefox", "custom"]
    @configuration.browsers = expected_browsers

    index = 0
    @configuration.run_each_browser do
      @configuration.current_browser.should == expected_browsers[index]
      index += 1
    end
  end

  specify "selenese_interpreter__when_in_test_browser_mode__should_be_nil" do
    @configuration.test_browser_mode!
    @configuration.selenese_interpreter.should be_nil
  end

  specify "stop_interpreter_if_necessary__when_suite_passes__should_stop_interpreter" do
    mock_interpreter = "mock_interpreter"
    mock(mock_interpreter).stop.once
    @context.interpreter = mock_interpreter

    @configuration.stop_interpreter_if_necessary true
  end

  specify "stop_interpreter_if_necessary__when_suite_fails_and_keep_browser_open_on_failure__should_not_stop_interpreter" do
    mock_interpreter = "mock_interpreter"
    mock(mock_interpreter).stop.never
    @context.interpreter = mock_interpreter
    @context.keep_browser_open_on_failure = true

    @configuration.stop_interpreter_if_necessary false
  end

  specify "stop_interpreter_if_necessary__when_suite_fails_and_not_keep_browser_open_on_failure__should_stop_interpreter" do
    mock_interpreter = "mock_interpreter"
    mock(mock_interpreter).stop
    @context.interpreter = mock_interpreter
    @context.keep_browser_open_on_failure = false

    @configuration.stop_interpreter_if_necessary false
  end

  protected
  def should_establish_environment( env_var, expected_value, method_name=nil )
    method_name = env_var unless method_name
    @context.env = stub_env
    stub_env[env_var] = expected_value
    Seleniumrc::SeleniumConfiguration.send :establish_environment
    Seleniumrc::SeleniumConfiguration.instance.send(method_name).should == expected_value
  end

  def stub_env
    @stub_env ||= {}
  end

  def should_lazily_load(object, method_name, default_value)
    object.send(method_name).should == default_value
    test_object = Object.new
    object.send(method_name.to_s + "=", test_object)
    object.send(method_name).should == test_object
  end

end
end
