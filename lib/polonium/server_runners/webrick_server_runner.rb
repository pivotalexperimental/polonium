module Polonium
  module ServerRunners
    class WebrickServerRunner < ServerRunner
    attr_accessor :server

    def initialize(configuration)
      require 'webrick_server'
      super
    end

    protected
    def start_server
      @server = create_webrick_server
      mount_parameters = {
        :port            => configuration.internal_app_server_port,
        :ip              => configuration.internal_app_server_host,
        :environment     => configuration.rails_env.dup,
        :server_root     => configuration.server_root,
        :server_type     => WEBrick::SimpleServer,
        :charset         => "UTF-8",
        :mime_types      => WEBrick::HTTPUtils::DefaultMimeTypes,
        :working_directory => File.expand_path(configuration.rails_root.to_s)
      }
      server.mount('/', DispatchServlet, mount_parameters)

      trap("INT") { stop_server }

      require File.expand_path("#{configuration.rails_root}/config/environment")
      require "dispatcher"
      server.start
    end

    def stop_server
      server.shutdown if server
    end

    def create_webrick_server #:nodoc:
      WEBrick::HTTPServer.new({
        :Port => configuration.internal_app_server_port,
        :BindAddress => configuration.internal_app_server_host,
        :ServerType  => WEBrick::SimpleServer,
        :MimeTypes => WEBrick::HTTPUtils::DefaultMimeTypes,
        :Logger => configuration.new_logger,
        :AccessLog => []
      })
    end
  end
  end
end