require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
  describe SeleniumConfiguration, ".instance" do
    attr_reader :configuration
    before(:each) do
      SeleniumConfiguration.instance = nil
      @configuration = SeleniumConfiguration.new
    end

    it "should create a new context if it hasn't been called yet" do
      mock(SeleniumConfiguration).new.returns(configuration)
      SeleniumConfiguration.instance.should == configuration
    end

    it "should reuse the existing context if it has been called.  So new/establish_environment should only be called once." do
      SeleniumConfiguration.instance.should_not be_nil
      dont_allow(SeleniumConfiguration).new
    end
  end

  describe SeleniumConfiguration do
    attr_reader :configuration
    before(:each) do
      @configuration = SeleniumConfiguration.new
      @old_rails_root = RAILS_ROOT if Object.const_defined? :RAILS_ROOT
      silence_warnings { Object.const_set :RAILS_ROOT, "foobar" }
      require 'webrick_server'
    end

    after(:each) do
      if @old_rails_root
        silence_warnings { Object.const_set :RAILS_ROOT, @old_rails_root }
      else
        Object.instance_eval {remove_const :RAILS_ROOT}
      end
    end

    it "registers and notifies before_suite callbacks" do
      proc1_called = false
      proc1 = lambda {proc1_called = true}
      proc2_called = false
      proc2 = lambda {proc2_called = true}

      configuration.before_suite(&proc1)
      configuration.before_suite(&proc2)
      configuration.notify_before_suite
      proc1_called.should == true
      proc2_called.should == true
    end

    it "registers and notifies after_selenese_interpreter_started callbacks" do
      proc1_args = nil
      proc1 = lambda {|*args| proc1_args = args}
      proc2_args = nil
      proc2 = lambda {|*args| proc2_args = args}

      configuration.after_selenese_interpreter_started(&proc1)
      configuration.after_selenese_interpreter_started(&proc2)

      expected_interpreter = Object.new
      configuration.notify_after_selenese_interpreter_started(expected_interpreter)
      proc1_args.should == [expected_interpreter]
      proc2_args.should == [expected_interpreter]
    end

    it "creates app server checker" do
      app_server_checker = configuration.create_app_server_checker
      app_server_checker.context.should == configuration
      app_server_checker.tcp_socket_class.should == TCPSocket
    end

    it "defaults to true for verify_remote_app_server_is_running" do
      configuration.verify_remote_app_server_is_running.should ==  true
    end

    it "defaults app_server_initialization to a Proc" do
      configuration.app_server_initialization.should be_instance_of(Proc)
    end

    it "creates a Selenese interpreter and notify listeners" do
      configuration.selenium_server_host = "selenium_server_host.com"
      configuration.selenium_server_port = 80
      configuration.current_browser = "iexplore"
      configuration.external_app_server_host = "browser_host.com"
      configuration.external_app_server_port = 80

      interpreter = configuration.create_driver
      interpreter.server_host.should == "selenium_server_host.com"
      interpreter.server_port.should == 80
      interpreter.browser_start_command.should == "*iexplore"
      interpreter.browser_url.should == "http://browser_host.com:80"
    end

    it "creates, initializes. and notifies listeners for a Selenese interpreter " do
      passed_interpreter = nil
      configuration.after_selenese_interpreter_started {|interpreter| passed_interpreter = interpreter}

      stub_interpreter = Object.new
      start_called = false
      stub(stub_interpreter).start.returns {start_called = true}
      stub(configuration).create_driver.returns {stub_interpreter}
      interpreter = configuration.create_and_initialize_interpreter
      interpreter.should == stub_interpreter
      passed_interpreter.should == interpreter
      start_called.should == true
    end

    it "creates a Webrick Server Runner" do
      configuration.selenium_server_port = 4000
      configuration.selenium_server_host = "localhost"
      dir = File.dirname(__FILE__)
      configuration.rails_root = dir
      configuration.rails_env = "test"

      runner = configuration.create_webrick_runner
      runner.should be_an_instance_of(WebrickSeleniumServerRunner)
      runner.context.should == configuration
      runner.thread_class.should == Thread
      runner.socket.should == Socket
      runner.dispatch_servlet.should == DispatchServlet
      runner.environment_path.should == File.expand_path("#{dir}/config/environment")
    end

    it "creates webrick http server" do
      configuration.internal_app_server_port = 4000
      configuration.internal_app_server_host = "localhost"

      mock_logger = "logger"
      mock(configuration).new_logger.returns(mock_logger)
      mock(WEBrick::HTTPServer).new.with({
        :Port => 4000,
        :BindAddress => "localhost",
        :ServerType  => WEBrick::SimpleServer,
        :MimeTypes => WEBrick::HTTPUtils::DefaultMimeTypes,
        :Logger => mock_logger,
        :AccessLog => []
      })
      server = configuration.create_webrick_server
    end

    it "creates Mongrel Server Runner" do
      server = configuration.create_mongrel_runner
      server.should be_instance_of(MongrelSeleniumServerRunner)
      server.context.should == configuration
      server.thread_class.should == Thread
    end

    it "creates Mongrel configurator" do
      configuration.internal_app_server_host = "localhost"
      configuration.internal_app_server_port = 4000
      configuration.rails_env = "test"
      configuration.rails_root = rails_root = File.dirname(__FILE__)

      configurator = configuration.create_mongrel_configurator
      configurator.defaults[:host].should == "localhost"
      configurator.defaults[:port].should == 4000
      configurator.defaults[:cwd].should == configuration.rails_root
      configurator.defaults[:log_file].should == "#{configuration.rails_root}/log/mongrel.log"
      configurator.defaults[:pid_file].should == "#{configuration.rails_root}/log/mongrel.pid"
      configurator.defaults[:environment].should == "test"
      configurator.defaults[:docroot].should == "#{rails_root}/public"
      configurator.defaults[:mime_map].should be_nil
      configurator.defaults[:daemon].should == false
      configurator.defaults[:debug].should == false
      configurator.defaults[:includes].should == ["mongrel"]
      configurator.defaults[:config_script].should be_nil
    end
  end

  describe SeleniumConfiguration, "#establish_environment" do
    attr_reader :configuration
    before(:each) do
      @old_configuration = SeleniumConfiguration.instance
      SeleniumConfiguration.instance = nil
      @configuration = SeleniumConfiguration.instance
      configuration = @configuration
    end

    after(:each) do
      SeleniumConfiguration.instance = @old_configuration
    end

    it "establish_environment__webrick_host" do
      should_establish_environment('internal_app_server_host', '192.168.10.1', :internal_app_server_host )
    end

    it "initializes webrick_port" do
      should_establish_environment('internal_app_server_port', 1337, :internal_app_server_port )
    end

    it "initializes internal_app_server_port" do
      should_establish_environment('external_app_server_port', 1337, :external_app_server_port )
    end

    it "initializes internal_app_server_host" do
      should_establish_environment('external_app_server_host', 'sammich.com', :external_app_server_host)
    end

    it "initializes selenium_server_host" do
      should_establish_environment('selenium_server_host', 'sammich.com')
    end

    it "initializes selenium_server_host" do
      should_establish_environment('selenium_server_port', 1337)
    end

    it "initializes app_server_engine" do
      should_establish_environment('app_server_engine', :webrick, :app_server_engine)
    end

    it "initializes browsers" do
      configuration.env = stub_env
      env_var = "browsers"
      expected_value = 'konqueror'
      stub_env[env_var] = expected_value
      SeleniumConfiguration.send :establish_environment
      configuration.browsers.should == [expected_value]
    end

    it "initializes keep_browser_open_on_failure" do
      configuration.env = stub_env
      env_var = 'keep_browser_open_on_failure'
      stub_env[env_var] = 'false'
      SeleniumConfiguration.send :establish_environment
      configuration.send(env_var).should == false
      configuration.send(env_var).should == false

      stub_env[env_var] = 'true'
      SeleniumConfiguration.send :establish_environment
      configuration.send(env_var).should == true
      configuration.send(env_var).should == true

      stub_env[env_var] = 'blah'
      SeleniumConfiguration.send :establish_environment
      configuration.send(env_var).should == true
      configuration.send(env_var).should == true
    end

    it "initializes verify_remote_app_server_is_running" do
      configuration.env = stub_env
      env_var = 'verify_remote_app_server_is_running'
      stub_env[env_var] = 'false'
      SeleniumConfiguration.send :establish_environment
      configuration.send(env_var).should == false
      configuration.send(env_var).should == false

      stub_env[env_var] = 'true'
      SeleniumConfiguration.send :establish_environment
      configuration.send(env_var).should == true
      configuration.send(env_var).should == true

      stub_env[env_var] = 'blah'
      SeleniumConfiguration.send :establish_environment
      configuration.send(env_var).should == true
      configuration.send(env_var).should == true
    end

    it "internal_app_server_host" do
      should_lazily_load configuration, :internal_app_server_host, "0.0.0.0"
    end

    it "internal_app_server_port" do
      should_lazily_load configuration, :internal_app_server_port, 4000
    end

    it "external_app_server_host" do
      should_lazily_load configuration, :external_app_server_host, "localhost"
    end

    it "external_app_server_port" do
      should_lazily_load configuration, :external_app_server_port, 4000
    end

    it "browsers__lazy_loaded" do
      should_lazily_load configuration, :browsers, [SeleniumConfiguration::FIREFOX]
    end

    it "keep_browser_open_on_failure" do
      should_lazily_load configuration, :keep_browser_open_on_failure, true
    end

    it "formatted_browser" do
      configuration.current_browser = SeleniumConfiguration::IEXPLORE
      configuration.formatted_browser.should == "*iexplore"
    end

    it "browser_url" do
      configuration.external_app_server_host = "test.com"
      configuration.external_app_server_port = 101
      configuration.browser_url.should == "http://test.com:101"
    end

    it "run_each_browser_within_the_browsers" do
      expected_browsers = ["iexplore", "firefox", "custom"]
      configuration.browsers = expected_browsers

      index = 0
      configuration.run_each_browser do
        configuration.current_browser.should == expected_browsers[index]
        index += 1
      end
    end

    it "selenese_interpreter__when_in_test_browser_mode__should_be_nil" do
      configuration.test_browser_mode!
      configuration.selenese_interpreter.should be_nil
    end

    protected
    def should_establish_environment(env_var, expected_value, method_name=nil )
      method_name = env_var unless method_name
      configuration.env = stub_env
      stub_env[env_var] = expected_value
      SeleniumConfiguration.send :establish_environment
      SeleniumConfiguration.instance.send(method_name).should == expected_value
    end

    def stub_env
      @stub_env ||= {}
    end

    def should_lazily_load(object, method_name, default_value)
      object.send(method_name).should == default_value
      test_object = Object.new
      object.send("#{method_name}=", test_object)
      object.send(method_name).should == test_object
    end
  end

  describe SeleniumConfiguration, "#stop_interpreter_if_necessary" do
    attr_reader :configuration
    before(:each) do
      @configuration = SeleniumConfiguration.new
    end

    it "when suite passes, should stop interpreter" do
      mock_interpreter = "mock_interpreter"
      mock(mock_interpreter).stop.once
      configuration.interpreter = mock_interpreter

      configuration.stop_interpreter_if_necessary true
    end

    it "when suite fails and keep browser open on failure, should not stop interpreter" do
      mock_interpreter = "mock_interpreter"
      mock(mock_interpreter).stop.never
      configuration.interpreter = mock_interpreter
      configuration.keep_browser_open_on_failure = true

      configuration.stop_interpreter_if_necessary false
    end

    it "when suite fails and not keep browser open on failure, should stop interpreter" do
      mock_interpreter = "mock_interpreter"
      mock(mock_interpreter).stop
      configuration.interpreter = mock_interpreter
      configuration.keep_browser_open_on_failure = false

      configuration.stop_interpreter_if_necessary false
    end

  end

  describe SeleniumConfiguration, "#create_server_runner where application server engine is mongrel" do
    it "creates a mongrel server runner" do
      context = SeleniumConfiguration.new
      context.app_server_engine = :mongrel
      runner = context.create_server_runner
      runner.should be_instance_of(MongrelSeleniumServerRunner)
    end
  end

  context SeleniumConfiguration, "#create_server_runner where application server engine is webrick" do
    before do
      Object.const_set :RAILS_ROOT, "foobar"
      require 'webrick_server'
    end

    after do
      Object.instance_eval {remove_const :RAILS_ROOT}
    end

    it "creates a webrick server runner" do
      context = SeleniumConfiguration.new
      context.app_server_engine = :webrick
      runner = context.create_server_runner
      runner.should be_instance_of(WebrickSeleniumServerRunner)
    end
  end
end
