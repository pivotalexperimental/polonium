module Seleniumrc
  # The configuration interface. This SeleniumConfiguration acts as a singleton to a SeleniumContext.
  # You can access the SeleniumConfiguration object by calling
  #   Seleniumrc::SeleniumConfiguration.instance
  class SeleniumConfiguration
    module BrowserMode
      Suite = "suite" unless const_defined? :Suite
      Test = "test" unless const_defined? :Test
    end
    FIREFOX = "firefox" unless const_defined? :FIREFOX
    IEXPLORE = "iexplore" unless const_defined? :IEXPLORE

    class << self
      # The instance of the Singleton SeleniumConfiguration. On its initial call, the initial configuration is set.
      # The initial configuration is based on Environment variables and defaults.
      # The environment variables are:
      # * RAILS_ENV - The Rails environment (defaults: test)
      # * selenium_server_host - The host name for the Selenium RC server (default: localhost)
      # * selenium_server_port - The port for the Selenium RC server (default: 4444)
      # * webrick_host - The host name that the application server will start under (default: localhost)
      # * webrick_port - The port that the application server will start under (default: 4000)
      # * app_server_engine - The type of server the application will be run with (webrick or mongrel)
      # * browsers - A comma-delimited list of browsers that will be tested (e.g. firebox,iexplore)
      # * internal_app_server_host - The host name for the Application server that the Browser will access (default: localhost)
      # * internal_app_server_host - The port for the Application server that the Browser will access (default: 4000)
      # * keep_browser_open_on_failure - If there is a failure in the test suite, keep the browser window open (default: true)
      # * verify_remote_app_server_is_running - Raise an exception if the Application Server is not running (default: true)
      def instance
        return @instance if @instance
        @instance = new
        @instance.env = ENV

        # TODO: BT - We need to only run one browser per run. Having an array makes the architecture wack.
        @instance.browsers = [FIREFOX] # Crack is wack
        @instance.failure_has_not_occurred!
        @instance.selenium_server_host = "localhost"     # address of selenium RC server (java)
        @instance.selenium_server_port = 4444
        @instance.app_server_engine = :webrick
        @instance.internal_app_server_host = "0.0.0.0"    # internal address of app server (webrick)
        @instance.internal_app_server_port = 4000
        @instance.external_app_server_host = "localhost"             # external address of app server (webrick)
        @instance.external_app_server_port = 4000
        @instance.server_engine = :webrick
        @instance.keep_browser_open_on_failure = true
        @instance.browser_mode = BrowserMode::Suite
        @instance.verify_remote_app_server_is_running = true

        establish_environment
        @instance
      end
      attr_writer :instance

      private
      def establish_environment
        @instance.rails_env = env['RAILS_ENV'] if env.include?('RAILS_ENV')
        @instance.rails_root = Object.const_get(:RAILS_ROOT) if Object.const_defined?(:RAILS_ROOT)
        ['selenium_server_host', 'selenium_server_port', 'internal_app_server_port', 'internal_app_server_host',
          'app_server_engine', 'external_app_server_host', 'external_app_server_port'].each do |env_key|
          @instance.send(env_key + "=", env[env_key]) if env.include?(env_key)
        end
        ['keep_browser_open_on_failure', 'verify_remote_app_server_is_running'].each do |env_key|
          @instance.send(env_key + "=", env[env_key].to_s != false.to_s) if env.include?(env_key)
        end
        ['browsers'].each do |env_key|
          @instance.send(env_key + "=", env[env_key].split(",")) if env.include?(env_key)
        end
      end

      def env
        @instance.env
      end
    end

        attr_accessor :configuration,
                  :env,
                  :rails_env,
                  :rails_root,
                  :browsers,
                  :current_browser,
                  :interpreter,
                  :browser_mode,
                  :selenium_server_host,
                  :selenium_server_port,
                  :app_server_engine,
                  :internal_app_server_host,
                  :internal_app_server_port,
                  :external_app_server_host,
                  :external_app_server_port,
                  :server_engine,
                  :keep_browser_open_on_failure,
                  :verify_remote_app_server_is_running,
                  :app_server_initialization

    def initialize
      self.verify_remote_app_server_is_running = true
      @before_suite_listeners = []
      @after_selenese_interpreter_started_listeners = []
      @app_server_initialization = proc {}
    end

    # A callback hook that gets run before the suite is run.
    def before_suite(&block)
      @before_suite_listeners << block
    end

    # Notify all before_suite callbacks.
    def notify_before_suite
      for listener in @before_suite_listeners
        listener.call
      end
    end

    # A callback hook that gets run after the Selenese Interpreter is started.
    def after_selenese_interpreter_started(&block)
      @after_selenese_interpreter_started_listeners << block
    end

    # Notify all after_selenese_interpreter_started callbacks.
    def notify_after_selenese_interpreter_started(interpreter)
      for listener in @after_selenese_interpreter_started_listeners
        listener.call(interpreter)
      end
    end

    # The browser formatted for the Selenese interpreter.
    def formatted_browser
      return "*#{@current_browser}"
    end

    # Has a failure occurred in the tests?
    def failure_has_occurred?
      @failure_has_occurred = true
    end

    # Sets the failure state to true
    def failure_has_occurred!
      @failure_has_occurred = true
    end

    # Sets the failure state to false
    def failure_has_not_occurred!
      @failure_has_occurred = false
    end

    # The http host name and port to be entered into the browser address bar
    def browser_url
      "http://#{external_app_server_host}:#{external_app_server_port}"
    end

    # The root directory (public) of the Rails application
    def server_root
      File.expand_path("#{rails_root}/public/")
    end

    # Sets the Test Suite to open a new browser instance for each TestCase
    def test_browser_mode!
      @browser_mode = SeleniumConfiguration::BrowserMode::Test
    end

    # Are we going to open a new browser instance for each TestCase?
    def test_browser_mode?
      @browser_mode == SeleniumConfiguration::BrowserMode::Test
    end

    # Sets the Test Suite to use one browser instance
    def suite_browser_mode!
      @browser_mode = SeleniumConfiguration::BrowserMode::Suite
    end

    # Does the Test Suite to use one browser instance?
    def suite_browser_mode?
      @browser_mode == SeleniumConfiguration::BrowserMode::Suite
    end

    def run_each_browser # nodoc
      browsers.each do |browser|
        self.current_browser = browser
        yield
        break if @failure_has_occurred
      end
    end

    # The Selenese Interpreter object. This is the Interpreter provided by the Selenium RC (http://openqa.org/selenium-rc/) project.
    def selenese_interpreter
      return nil unless suite_browser_mode?
      unless @interpreter
        @interpreter = create_and_initialize_interpreter
      end
      @interpreter
    end

    def stop_interpreter_if_necessary(suite_passed) # nodoc
      failure_has_occurred! unless suite_passed
      if @interpreter && stop_selenese_interpreter?(suite_passed)
        @interpreter.stop
        @interpreter = nil
      end
    end

    def stop_selenese_interpreter?(passed) # nodoc
      return true if passed
      return !keep_browser_open_on_failure
    end

    def create_app_server_checker # nodoc
      app_server_checker = AppServerChecker.new()
      app_server_checker.context = self
      app_server_checker.tcp_socket_class = TCPSocket
      return app_server_checker
    end

    def create_and_initialize_interpreter # nodoc
      interpreter = create_driver
      interpreter.start
      notify_after_selenese_interpreter_started(interpreter)
      interpreter
    end

    def create_driver # nodoc
      return ::Seleniumrc::SeleniumDriver.new(
        selenium_server_host,
        selenium_server_port,
        formatted_browser,
        browser_url,
        15000
      )
    end

    def create_server_runner # nodoc
      case @app_server_engine.to_sym
      when :mongrel
        create_mongrel_runner
      when :webrick
        create_webrick_runner
      else
        raise "Invalid server type: #{selenium_context.app_server_type}"
      end
    end

    def create_webrick_runner # nodoc
      require 'webrick_server'
      runner = WebrickSeleniumServerRunner.new
      runner.context = self
      runner.thread_class = Thread
      runner.socket = Socket
      runner.dispatch_servlet = DispatchServlet
      runner.environment_path = File.expand_path("#{@rails_root}/config/environment")
      runner
    end

    def create_webrick_server # nodoc
      WEBrick::HTTPServer.new({
        :Port => @internal_app_server_port,
        :BindAddress => @internal_app_server_host,
        :ServerType  => WEBrick::SimpleServer,
        :MimeTypes => WEBrick::HTTPUtils::DefaultMimeTypes,
        :Logger => new_logger,
        :AccessLog => []
      })
    end

    def new_logger
      Logger.new(StringIO.new)
    end

    def create_mongrel_runner # nodoc
      runner = MongrelSeleniumServerRunner.new
      runner.context = self
      runner.thread_class = Thread
      runner
    end

    def create_mongrel_configurator # nodoc
      dir = File.dirname(__FILE__)
      require 'mongrel/rails'
      settings = {
        :host => internal_app_server_host,
        :port => internal_app_server_port,
        :cwd => @rails_root,
        :log_file => "#{@rails_root}/log/mongrel.log",
        :pid_file => "#{@rails_root}/log/mongrel.pid",
        :environment => @rails_env,
        :docroot => "#{@rails_root}/public",
        :mime_map => nil,
        :daemon => false,
        :debug => false,
        :includes => ["mongrel"],
        :config_script => nil
      }

      configurator = Mongrel::Rails::RailsConfigurator.new(settings) do
        log "Starting Mongrel in #{defaults[:environment]} mode at #{defaults[:host]}:#{defaults[:port]}"
      end
      configurator
    end
  end
end