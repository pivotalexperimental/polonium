module SeleniumrcFu
  # The application state and Dependency Injection container of the SeleniumrcFu objects.
  # All objects are created through the SeleniumContext. All global state is encapsulated here.
  class SeleniumContext
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
                  :verify_remote_app_server_is_running

    def initialize
      self.verify_remote_app_server_is_running = true
      @before_suite_listeners = []
      @after_selenese_interpreter_started_listeners = []
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
      interpreter = create_interpreter
      interpreter.start
      notify_after_selenese_interpreter_started(interpreter)
      interpreter
    end

    def create_interpreter # nodoc
      return Selenium::SeleneseInterpreter.new(
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
        :docroot => "public",
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