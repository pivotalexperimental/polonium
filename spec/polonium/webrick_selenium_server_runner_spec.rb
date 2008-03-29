require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe WebrickSeleniumServerRunner do
    attr_reader :configuration, :mock_server
    before(:each) do
      Object.const_set(:RAILS_ROOT, "foobar")
    end

    after(:each) do
      Object.instance_eval {remove_const :RAILS_ROOT}
    end

    it "start method should set socket.do_not_reverse_lookup to true and" do
      runner = create_runner_that_is_stubbed_so_start_method_works
      runner.start
    end

    it "start method should initialize the HttpServer with parameters" do
      runner = create_runner_that_is_stubbed_so_start_method_works
      runner.start
    end

    it "start method should mount and start the server" do
      runner = create_runner_that_is_stubbed_so_start_method_works
      runner.start
    end

    it "start method should require the environment and dispatcher" do
      runner = create_runner_that_is_stubbed_so_start_method_works

      mock(runner).require("foobar")
      mock(runner).require("dispatcher")

      runner.environment_path = "foobar"
      runner.start
    end

    it "start method should require environment when rails_root is not set" do
      runner = create_runner_that_is_stubbed_so_start_method_works
      requires = []
      stub(runner).require {|val| requires << val}

      runner.start
      requires.any? {|r| r =~ /\/config\/environment/}.should == true
    end

    it "start method should trap server.shutdown" do
      runner = create_runner_that_is_stubbed_so_start_method_works

      (
      class << runner;
        self;
      end).class_eval {attr_reader :trap_signal_name}
      def runner.trap(signal_name, &block)
        @trap_signal_name = signal_name
        block.call
      end
      mock(mock_server).shutdown

      runner.start
      runner.trap_signal_name.should == "INT"
    end

    it "should shutdown webrick server" do
      runner = create_runner_that_is_stubbed_so_start_method_works
      runner.start
      mock(mock_server).shutdown
      runner.stop
    end

    def create_runner_that_is_stubbed_so_start_method_works
      configuration = Polonium::Configuration.new
      runner = configuration.create_webrick_runner
      class << runner;
        public :start_server;
      end

      stub(runner).require

      stub(mock_socket = "mock_socket").do_not_reverse_lookup=(true)
      runner.socket = mock_socket

      configuration.internal_app_server_port = 4000
      configuration.internal_app_server_host = "localhost"
      configuration.rails_env = "test"
      
      @mock_server = "mock_server"
      stub(WEBrick::HTTPServer).new {mock_server}

      stub(mock_server).mount('/')
      mock(mock_server) do |s|
        s.mount(
          '/',
          DispatchServlet,
          {
            :port            => configuration.internal_app_server_port,
            :ip              => configuration.internal_app_server_host,
            :environment     => configuration.rails_env,
            :server_root     => File.expand_path("#{configuration.rails_root}/public/"),
            :server_type     => WEBrick::SimpleServer,
            :charset         => "UTF-8",
            :mime_types      => WEBrick::HTTPUtils::DefaultMimeTypes,
            :working_directory => File.expand_path(configuration.rails_root.to_s)
          }
        )
        s.start
      end

      mock_thread_class = "mock_thread_class"
      runner.thread_class = mock_thread_class
      mock(mock_thread_class).start {|block| block.call}

      return runner
    end

    describe "#create_webrick_server" do
      it "creates webrick http server" do
        configuration = Polonium::Configuration.new
        configuration.internal_app_server_port = 4000
        configuration.internal_app_server_host = "localhost"

        mock_logger = "logger"
        mock(configuration).new_logger {mock_logger}
        mock(WEBrick::HTTPServer).new({
          :Port => 4000,
          :BindAddress => "localhost",
          :ServerType  => WEBrick::SimpleServer,
          :MimeTypes => WEBrick::HTTPUtils::DefaultMimeTypes,
          :Logger => mock_logger,
          :AccessLog => []
        })
        runner = configuration.create_webrick_runner
        server = runner.send(:create_webrick_server)
      end
    end

  end
end
