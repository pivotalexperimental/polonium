require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe Configuration do
    attr_reader :configuration
    before(:each) do
      @configuration = Configuration.new
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

    it "registers and notifies after_driver_started callbacks" do
      proc1_args = nil
      proc1 = lambda {|*args| proc1_args = args}
      proc2_args = nil
      proc2 = lambda {|*args| proc2_args = args}

      configuration.after_driver_started(&proc1)
      configuration.after_driver_started(&proc2)

      expected_driver = Object.new
      configuration.notify_after_driver_started(expected_driver)
      proc1_args.should == [expected_driver]
      proc2_args.should == [expected_driver]
    end

    it "defaults to true for verify_remote_app_server_is_running" do
      configuration.verify_remote_app_server_is_running.should ==  true
    end

    it "defaults app_server_initialization to a Proc" do
      configuration.app_server_initialization.should be_instance_of(Proc)
    end

    it "creates a Selenese driver and notify listeners" do
      configuration.selenium_server_host = "selenium_server_host.com"
      configuration.selenium_server_port = 80
      configuration.browser = "iexplore"
      configuration.external_app_server_host = "browser_host.com"
      configuration.external_app_server_port = 80

      driver = configuration.create_driver
      driver.server_host.should == "selenium_server_host.com"
      driver.server_port.should == 80
      driver.browser_start_command.should == "*iexplore"
      driver.browser_url.should == "http://browser_host.com:80"
    end

    it "creates, initializes. and notifies listeners for a Selenese driver " do
      passed_driver = nil
      configuration.after_driver_started {|driver| passed_driver = driver}

      stub_driver = Object.new
      start_called = false
      stub(stub_driver).start.returns {start_called = true}
      stub(configuration).create_driver.returns {stub_driver}
      driver = configuration.create_and_initialize_driver
      driver.should == stub_driver
      passed_driver.should == driver
      start_called.should == true
    end
  end

  describe ".instance" do
    attr_reader :configuration
    before(:each) do
      Configuration.instance = nil
      @configuration = Configuration.new
    end

    it "should create a new Configuration if it hasn't been called yet" do
      mock(Configuration).new.returns(configuration)
      Configuration.instance.should == configuration
    end

    it "should reuse the existing Configuration if it has been called.  So new/establish_environment should only be called once." do
      Configuration.instance.should_not be_nil
      dont_allow(Configuration).new
    end
  end

  describe "#establish_environment" do
    attr_reader :configuration
    before(:each) do
      @old_configuration = Configuration.instance
      Configuration.instance = nil
      @configuration = Configuration.instance
      configuration = @configuration
    end

    after(:each) do
      Configuration.instance = @old_configuration
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

    it "initializes browser" do
      configuration.env = stub_env
      stub_env['browser'] = 'konqueror'
      Configuration.__send__(:establish_environment)
      configuration.browser.should == 'konqueror'
    end

    it "initializes keep_browser_open_on_failure" do
      configuration.env = stub_env
      env_var = 'keep_browser_open_on_failure'
      stub_env[env_var] = 'false'
      Configuration.send :establish_environment
      configuration.send(env_var).should == false
      configuration.send(env_var).should == false

      stub_env[env_var] = 'true'
      Configuration.send :establish_environment
      configuration.send(env_var).should == true
      configuration.send(env_var).should == true

      stub_env[env_var] = 'blah'
      Configuration.send :establish_environment
      configuration.send(env_var).should == true
      configuration.send(env_var).should == true
    end

    it "initializes verify_remote_app_server_is_running" do
      configuration.env = stub_env
      env_var = 'verify_remote_app_server_is_running'
      stub_env[env_var] = 'false'
      Configuration.send :establish_environment
      configuration.send(env_var).should == false
      configuration.send(env_var).should == false

      stub_env[env_var] = 'true'
      Configuration.send :establish_environment
      configuration.send(env_var).should == true
      configuration.send(env_var).should == true

      stub_env[env_var] = 'blah'
      Configuration.send :establish_environment
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
      should_lazily_load configuration, :external_app_server_host, '127.0.0.1'
    end

    it "external_app_server_port" do
      should_lazily_load configuration, :external_app_server_port, 4000
    end

    it "browsers__lazy_loaded" do
      should_lazily_load configuration, :browser, Configuration::FIREFOX
    end

    it "keep_browser_open_on_failure" do
      should_lazily_load configuration, :keep_browser_open_on_failure, false
    end

    it "formatted_browser" do
      configuration.browser = Configuration::IEXPLORE
      configuration.formatted_browser.should == "*iexplore"
    end

    it "browser_url" do
      configuration.external_app_server_host = "test.com"
      configuration.external_app_server_port = 101
      configuration.browser_url.should == "http://test.com:101"
    end

    it "driver__when_in_test_browser_mode__should_be_nil" do
      configuration.test_browser_mode
      configuration.driver.should be_nil
    end

    protected
    def should_establish_environment(env_var, expected_value, method_name=nil )
      method_name = env_var unless method_name
      configuration.env = stub_env
      stub_env[env_var] = expected_value
      Configuration.send :establish_environment
      Configuration.instance.send(method_name).should == expected_value
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

  describe "#stop_driver_if_necessary" do
    attr_reader :configuration
    before(:each) do
      @configuration = Configuration.new
    end

    it "when suite passes, should stop driver" do
      driver = ::Polonium::Driver.new('http://test.host', 4000, "*firefox", 'http://test.host')
      mock(driver).stop.once
      configuration.driver = driver

      configuration.stop_driver_if_necessary true
    end

    it "when suite fails and keep browser open on failure, should not stop driver" do
      driver = ::Polonium::Driver.new('http://test.host', 4000, "*firefox", 'http://test.host')
      mock(driver).stop.never
      configuration.driver = driver
      configuration.keep_browser_open_on_failure = true

      configuration.stop_driver_if_necessary false
    end

    it "when suite fails and not keep browser open on failure, should stop driver" do
      driver = ::Polonium::Driver.new('http://test.host', 4000, "*firefox", 'http://test.host')
      mock(driver).stop
      configuration.driver = driver
      configuration.keep_browser_open_on_failure = false

      configuration.stop_driver_if_necessary false
    end

  end

  describe "#create_app_server_runner" do
    describe "when server engine in mongrel" do
      it "creates a mongrel server runner" do
        configuration = Configuration.new
        configuration.app_server_engine = :mongrel
        runner = configuration.create_app_server_runner
        runner.class.should == ServerRunners::MongrelServerRunner
        runner.configuration.should == configuration
      end
    end

    describe "when server engine is webrick" do
      before do
        Object.const_set :RAILS_ROOT, "foobar"
      end

      after do
        Object.instance_eval {remove_const :RAILS_ROOT}
      end

      it "creates a webrick server runner" do
        configuration = Configuration.new
        configuration.app_server_engine = :webrick
        runner = configuration.create_app_server_runner
        runner.class.should == ServerRunners::WebrickServerRunner
        runner.configuration.should == configuration
      end
    end
  end
end
