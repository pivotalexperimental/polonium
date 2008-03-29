module Polonium
  module ServerRunners
    class ServerRunner
      attr_reader :configuration
      def initialize(configuration)
        @configuration = configuration
        @started = false
      end

      def start
        Thread.start do
          start_server
        end
        @started = true
      end

      def stop
        stop_server
        @started = false
      end

      def started?
        @started
      end

      protected
      def start_server
        raise NotImplementedError.new("this is abstract!")
      end

      def stop_server
        raise NotImplementedError.new("this is abstract!")
      end
    end
  end
end