module Seleniumrc
  class MongrelSeleniumServerRunner < SeleniumServerRunner
    def start
      mongrel_configurator = configuration.create_mongrel_configurator
      initialize_server(mongrel_configurator)

      @thread_class.start do
        start_server(mongrel_configurator)
      end
      @started = true
    end

    protected
    def start_server(mongrel_configurator)
      mongrel_configurator.run
      mongrel_configurator.log "Mongrel running at #{configuration.internal_app_server_host}:#{configuration.internal_app_server_port}"
      mongrel_configurator.join
    end

    def initialize_server(config)
      configuration = self.configuration
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