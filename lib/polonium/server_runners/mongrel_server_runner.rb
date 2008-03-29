module Polonium
  module ServerRunners
    class MongrelServerRunner < ServerRunner
      def start
        mongrel_configurator = create_mongrel_configurator
        initialize_server(mongrel_configurator)

        Thread.start do
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

      def create_mongrel_configurator #:nodoc:
        dir = File.dirname(__FILE__)
        require 'mongrel/rails'
        settings = {
          :host => configuration.internal_app_server_host,
          :port => configuration.internal_app_server_port,
          :cwd => configuration.rails_root,
          :log_file => "#{configuration.rails_root}/log/mongrel.log",
          :pid_file => "#{configuration.rails_root}/log/mongrel.pid",
          :environment => configuration.rails_env,
          :docroot => "#{configuration.rails_root}/public",
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
end