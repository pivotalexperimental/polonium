module Polonium
  # The configuration interface. This Configuration acts as a singleton to a SeleniumContext.
  # You can access the Configuration object by calling
  #   Polonium::Configuration.instance
  class Configuration
    module BrowserMode
      Suite = "suite" unless const_defined? :Suite
      Test = "test" unless const_defined? :Test
    end
    FIREFOX = "firefox" unless const_defined? :FIREFOX
    IEXPLORE = "iexplore" unless const_defined? :IEXPLORE
    SERVER_RUNNERS = {
      :webrick => ServerRunners::WebrickServerRunner,
      :mongrel => ServerRunners::MongrelServerRunner,
      :external => ServerRunners::ExternalServerRunner
    } unless const_defined? :SERVER_RUNNERS

    class << self
      # The instance of the Singleton Configuration. On its initial call, the initial configuration is set.
      # The initial configuration is based on Environment variables and defaults.
      # The environment variables are:
      # * RAILS_ENV - The Rails environment (defaults: test)
      # * selenium_server_host - The host name for the Selenium RC server (default: localhost)
      # * selenium_server_port - The port for the Selenium RC server (default: 4444)
      # * external_app_server_host - The host name that the Rails application server will start under (default: localhost)
      # * external_app_server_port - The port that the Rails application server will start under (default: 4000)
      # * app_server_engine - The type of server the application will be run with (webrick or mongrel)
      # * internal_app_server_host - The host name for the Application server that the Browser will access (default: localhost)
      # * internal_app_server_host - The port for the Application server that the Browser will access (default: 4000)
      # * keep_browser_open_on_failure - If there is a failure in the test suite, keep the browser window open (default: false)
      # * verify_remote_app_server_is_running - Raise an exception if the Application Server is not running (default: true)
      def instance
        @instance ||= begin
          @instance = new
          @instance.env = ENV

          @instance.browser = FIREFOX
          @instance.selenium_server_host = '127.0.0.1'     # address of selenium RC server (java)
          @instance.selenium_server_port = 4444
          @instance.app_server_engine = :webrick
          @instance.internal_app_server_host = "0.0.0.0"    # internal address of app server (webrick or mongrel)
          @instance.internal_app_server_port = 4000
          @instance.external_app_server_host = '127.0.0.1'             # external address of app server (webrick or mongrel)
          @instance.external_app_server_port = 4000
          @instance.server_engine = :webrick
          @instance.keep_browser_open_on_failure = false
          @instance.browser_mode = BrowserMode::Suite
          @instance.verify_remote_app_server_is_running = true

          establish_environment
          @instance
        end
      end
      attr_writer :instance

      private
      def establish_environment
        instance.rails_env = env['RAILS_ENV'] if env.include?('RAILS_ENV')
        instance.rails_root = Object.const_get(:RAILS_ROOT) if Object.const_defined?(:RAILS_ROOT)
        [
          'selenium_server_host',
          'selenium_server_port',
          'internal_app_server_port',
          'internal_app_server_host',
          'app_server_engine',
          'external_app_server_host',
          'external_app_server_port'
        ].each do |env_key|
          if env.include?(env_key)
            instance.send("#{env_key}=", env[env_key])
          end
        end
        [
          'keep_browser_open_on_failure',
          'verify_remote_app_server_is_running'
        ].each do |env_key|
          if env.include?(env_key)
            instance.send("#{env_key}=", env[env_key].to_s != false.to_s)
          end
        end
        instance.browser = env['browser'] if env.include?('browser')
      end

      def env
        instance.env
      end
    end

    attr_accessor(
      :env,
      :rails_env,
      :rails_root,
      :browser,
      :driver,
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
    )

    def initialize
      self.verify_remote_app_server_is_running = true
      @after_driver_started_listeners = []
      @app_server_initialization = proc {}
    end

    # A callback hook that gets run after the Selenese Interpreter is started.
    def after_driver_started(&block)
      @after_driver_started_listeners << block
    end

    # Notify all after_driver_started callbacks.
    def notify_after_driver_started(driver)
      for listener in @after_driver_started_listeners
        listener.call(driver)
      end
    end

    # The browser formatted for the Selenese driver.
    def formatted_browser
      return "*#{@browser}"
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
    def test_browser_mode
      @browser_mode = Configuration::BrowserMode::Test
    end

    # Are we going to open a new browser instance for each TestCase?
    def test_browser_mode?
      @browser_mode == Configuration::BrowserMode::Test
    end

    # Sets the Test Suite to use one browser instance
    def suite_browser_mode
      @browser_mode = Configuration::BrowserMode::Suite
    end

    # Does the Test Suite to use one browser instance?
    def suite_browser_mode?
      @browser_mode == Configuration::BrowserMode::Suite
    end

    # The Driver object, which sublcasses the Driver provided by the Selenium RC (http://openqa.org/selenium-rc/) project.
    def driver
      return nil unless suite_browser_mode?
      @driver ||= create_and_initialize_driver
    end

    def stop_driver_if_necessary(suite_passed) #:nodoc:
      if @driver && stop_driver?(suite_passed)
        @driver.stop
        @driver = nil
      end
    end

    def stop_driver?(passed) #:nodoc:
      return true if passed
      return !keep_browser_open_on_failure
    end

    def create_and_initialize_driver #:nodoc:
      driver = create_driver
      driver.start
      notify_after_driver_started(driver)
      driver
    end

    def create_driver #:nodoc:
      return ::Polonium::Driver.new(
        selenium_server_host,
        selenium_server_port,
        formatted_browser,
        browser_url,
        15000
      )
    end

    attr_reader :app_server_runner
    def create_app_server_runner #:nodoc:
      app_server_type = SERVER_RUNNERS[@app_server_engine.to_sym]
      raise "Invalid server engine #{@app_server_engine}" unless app_server_type
      @app_server_runner = app_server_type.new(self)
    end

    def new_logger
      Logger.new(StringIO.new)
    end
  end
end