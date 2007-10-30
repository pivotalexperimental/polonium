module Seleniumrc
  class MongrelSeleniumServerRunner < SeleniumServerRunner
    def start
      @configurator = @configuration.create_mongrel_configurator
      initialize_server(@configurator)

      @thread_class.start do
        start_server
      end
      @started = true
    end

    protected
    def start_server
      @configurator.run
      @configurator.log "Mongrel running at #{@configuration.internal_app_server_host}:#{@configuration.internal_app_server_port}"
      @configurator.join
    end

    def initialize_server(config)
      configuration = @configuration
      config.listener do |*args|
        mongrel = (args.first || self)
        mongrel.log "Starting Rails in environment #{defaults[:environment]} ..."
        mongrel.uri "/", :handler => mongrel.rails
        mongrel.log "Rails loaded."

        mongrel.log "Loading any Rails specific GemPlugins"
        mongrel.load_plugins
        configuration.app_server_initialization.call(mongrel)
      end
    end

    def stop_server
    end
  end
end