require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumContext do
  before(:each) do
    @context = Seleniumrc::SeleniumContext.new
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

    @context.before_suite(&proc1)
    @context.before_suite(&proc2)
    @context.notify_before_suite
    proc1_called.should == true
    proc2_called.should == true
  end

  it "registers and notifies after_selenese_interpreter_started callbacks" do
    proc1_args = nil
    proc1 = lambda {|*args| proc1_args = args}
    proc2_args = nil
    proc2 = lambda {|*args| proc2_args = args}

    @context.after_selenese_interpreter_started(&proc1)
    @context.after_selenese_interpreter_started(&proc2)

    expected_interpreter = Object.new
    @context.notify_after_selenese_interpreter_started(expected_interpreter)
    proc1_args.should == [expected_interpreter]
    proc2_args.should == [expected_interpreter]
  end

  it "creates app server checker" do
    app_server_checker = @context.create_app_server_checker
    app_server_checker.context.should == @context
    app_server_checker.tcp_socket_class.should == TCPSocket
  end

  it "defaults to true for verify_remote_app_server_is_running" do
    @context.verify_remote_app_server_is_running.should ==  true
  end

  it "creates a Selenese interpreter and notify listeners" do
    @context.selenium_server_host = "selenium_server_host.com"
    @context.selenium_server_port = 80
    @context.current_browser = "iexplore"
    @context.external_app_server_host = "browser_host.com"
    @context.external_app_server_port = 80

    interpreter = @context.create_interpreter
    interpreter.server_host.should == "selenium_server_host.com"
    interpreter.server_port.should == 80
    interpreter.browser_start_command.should == "*iexplore"
    interpreter.browser_url.should == "http://browser_host.com:80"
  end

  it "creates, initializes. and notifies listeners for a Selenese interpreter " do
    passed_interpreter = nil
    @context.after_selenese_interpreter_started {|interpreter| passed_interpreter = interpreter}

    stub_interpreter = Object.new
    start_called = false
    stub_interpreter.stub!(:start).and_return {start_called = true}
    @context.stub!(:create_interpreter).and_return {stub_interpreter}
    interpreter = @context.create_and_initialize_interpreter
    interpreter.should == stub_interpreter
    passed_interpreter.should == interpreter
    start_called.should == true
  end

  it "creates a Webrick Server Runner" do
    @context.selenium_server_port = 4000
    @context.selenium_server_host = "localhost"
    dir = File.dirname(__FILE__)
    @context.rails_root = dir
    @context.rails_env = "test"

    runner = @context.create_webrick_runner
    runner.should be_an_instance_of(Seleniumrc::WebrickSeleniumServerRunner)
    runner.context.should == @context
    runner.thread_class.should == Thread
    runner.socket.should == Socket
    runner.dispatch_servlet.should == DispatchServlet
    runner.environment_path.should == File.expand_path("#{dir}/config/environment")
  end

  it "creates webrick http server" do
    @context.internal_app_server_port = 4000
    @context.internal_app_server_host = "localhost"

    mock_logger = mock("logger")
    @context.should_receive(:new_logger).and_return(mock_logger)
    WEBrick::HTTPServer.should_receive(:new).with({
      :Port => 4000,
      :BindAddress => "localhost",
      :ServerType  => WEBrick::SimpleServer,
      :MimeTypes => WEBrick::HTTPUtils::DefaultMimeTypes,
      :Logger => mock_logger,
      :AccessLog => []
    })
    server = @context.create_webrick_server
  end

  it "creates Mongrel Server Runner" do
   server = @context.create_mongrel_runner
   server.should be_instance_of(Seleniumrc::MongrelSeleniumServerRunner)
   server.context.should == @context
   server.thread_class.should == Thread
  end

  it "creates Mongrel configurator" do
    @context.internal_app_server_host = "localhost"
    @context.internal_app_server_port = 4000
    @context.rails_env = "test"
    @context.rails_root = File.dirname(__FILE__)

    configurator = @context.create_mongrel_configurator
    configurator.defaults[:host].should == "localhost"
    configurator.defaults[:port].should == 4000
    configurator.defaults[:cwd].should == @context.rails_root
    configurator.defaults[:log_file].should == "#{@context.rails_root}/log/mongrel.log"
    configurator.defaults[:pid_file].should == "#{@context.rails_root}/log/mongrel.pid"
    configurator.defaults[:environment].should == "test"
    configurator.defaults[:docroot].should == "public"
    configurator.defaults[:mime_map].should be_nil
    configurator.defaults[:daemon].should == false
    configurator.defaults[:debug].should == false
    configurator.defaults[:includes].should == ["mongrel"]
    configurator.defaults[:config_script].should be_nil
  end
end

describe SeleniumContext, "#create_server_runner where application server engine is mongrel" do
  it "creates a mongrel server runner" do
    context = Seleniumrc::SeleniumContext.new
    context.app_server_engine = :mongrel
    runner = context.create_server_runner
    runner.should be_instance_of(MongrelSeleniumServerRunner)
  end
end

context SeleniumContext, "#create_server_runner where application server engine is webrick" do
  before do
    Object.const_set :RAILS_ROOT, "foobar"
    require 'webrick_server'
  end

  after do
    Object.instance_eval {remove_const :RAILS_ROOT}
  end

  it "creates a webrick server runner" do
    context = Seleniumrc::SeleniumContext.new
    context.app_server_engine = :webrick
    runner = context.create_server_runner
    runner.should be_instance_of(WebrickSeleniumServerRunner)
  end
end
end
