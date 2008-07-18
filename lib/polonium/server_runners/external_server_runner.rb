module Polonium
  module ServerRunners
    class ExternalServerRunner < ServerRunner
      protected
      def start_server
        stop_server
        system("cd #{configuration.rails_root}; script/server -e #{configuration.rails_env} -p #{configuration.internal_app_server_port} -c #{configuration.rails_root}")
      rescue Exception => e
        puts e.message
        puts e.backtrace
        raise e
      end

      def stop_server
        cmd = "ps ax | grep 'script/server -e #{configuration.rails_env}' | sed /grep/d | awk '{print $1}' | xargs kill -9 2>/dev/null"
        system(cmd)
      end
    end
  end
end