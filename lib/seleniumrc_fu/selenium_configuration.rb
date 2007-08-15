module SeleniumrcFu
  # The configuration interface. This SeleniumConfiguration acts as a singleton to a SeleniumContext.
  # You can access the SeleniumContext object by calling
  #   SeleniumrcFu::SeleniumContext.instance
  class SeleniumConfiguration
    module BrowserMode
      Suite = "suite" unless const_defined? :Suite
      Test = "test" unless const_defined? :Test
    end
    FIREFOX = "firefox" unless const_defined? :FIREFOX
    IEXPLORE = "iexplore" unless const_defined? :IEXPLORE

    module ClassMethods
      # The instance of the Singleton SeleniumContext. On its initial call, the initial configuration is set.
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
        return @context if @context
        @context = SeleniumContext.new
        @context.env = ENV

        # TODO: BT - We need to only run one browser per run. Having an array makes the architecture wack.
        @context.browsers = [FIREFOX] # Crack is wack
        @context.failure_has_not_occurred!
        @context.selenium_server_host = "localhost"     # address of selenium RC server (java)
        @context.selenium_server_port = 4444
        @context.app_server_engine = :webrick
        @context.internal_app_server_host = "0.0.0.0"    # internal address of app server (webrick)
        @context.internal_app_server_port = 4000
        @context.external_app_server_host = "localhost"             # external address of app server (webrick)
        @context.external_app_server_port = 4000
        @context.server_engine = :webrick
        @context.keep_browser_open_on_failure = true
        @context.browser_mode = BrowserMode::Suite
        @context.verify_remote_app_server_is_running = true

        establish_environment
        @context
      end

      private
      def context
        @context || SeleniumContext.new
      end

      def establish_environment
        @context.rails_env = env['RAILS_ENV'] if env.include?('RAILS_ENV')
        @context.rails_root = Object.const_get(:RAILS_ROOT) if Object.const_defined?(:RAILS_ROOT)
        ['selenium_server_host', 'selenium_server_port', 'internal_app_server_port', 'internal_app_server_host',
          'app_server_engine', 'external_app_server_host', 'external_app_server_port'].each do |env_key|
          @context.send(env_key + "=", env[env_key]) if env.include?(env_key)
        end
        ['keep_browser_open_on_failure', 'verify_remote_app_server_is_running'].each do |env_key|
          @context.send(env_key + "=", env[env_key].to_s != false.to_s) if env.include?(env_key)
        end
        ['browsers'].each do |env_key|
          @context.send(env_key + "=", env[env_key].split(",")) if env.include?(env_key)
        end
      end

      def env
        @context.env
      end
    end
    extend ClassMethods
  end
end