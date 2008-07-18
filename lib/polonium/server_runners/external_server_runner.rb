module Polonium
  module ServerRunners
    class ExternalServerRunner < ServerRunner
      protected
      def start_server
        stop_server
        system("cd #{RAILS_ROOT}; script/server -e #{ENV['RAILS_ENV']} -p #{configuration.internal_app_server_port} -c #{RAILS_ROOT}")
      rescue Exception => e
        puts e.message
        puts e.backtrace
        raise e
      end
      
      def stop_server
        cmd = "ps ax | grep 'script/server -e #{ENV['RAILS_ENV']}' | sed /grep/d | awk '{print $1}' | xargs kill -9 2>/dev/null"
        system(cmd)
      end  
    end
  end
end