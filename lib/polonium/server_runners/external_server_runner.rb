module Polonium
  module ServerRunners
    class ExternalServerRunner < ServerRunner
      class << self
        def start_server_command(&blk)
#          if blk
#            @start_server_command = blk
#          else
            @start_server_command ||= lambda do |configuration|
              "cd #{configuration.rails_root}; script/server -e #{configuration.rails_env} -p #{configuration.internal_app_server_port} -c #{configuration.rails_root}"
            end
#          end
        end

        def stop_server_command(&blk)
#          if blk
#            @stop_server_command = blk
#          else
            @stop_server_command ||= lambda do |configuration|
              "ps ax | grep 'script/server -e #{configuration.rails_env}' | sed /grep/d | awk '{print $1}' | xargs kill -9 2>/dev/null"
            end
#          end
        end
      end

      protected
      def start_server
        stop_server
        system(self.class.start_server_command.call(configuration))
      rescue Exception => e
        puts e.message
        puts e.backtrace
        raise e
      end

      def stop_server
        system(self.class.stop_server_command.call(configuration))
      end
    end
  end
end