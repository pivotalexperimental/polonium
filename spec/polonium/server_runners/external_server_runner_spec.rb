require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

module Polonium
  module ServerRunners
    describe ExternalServerRunner do
      attr_reader :configuration, :rails_env, :rails_root, :runner, :start_server_cmd, :stop_server_cmd
      before do
        @configuration = Configuration.new
        @rails_env = configuration.rails_env = 'test'
        @rails_root = configuration.rails_root = File.dirname(__FILE__)
        @start_server_cmd = "cd #{rails_root}; script/server -e #{rails_env} -p #{configuration.internal_app_server_port} -c #{rails_root}"
        @stop_server_cmd = "ps ax | grep 'script/server -e #{rails_env}' | sed /grep/d | awk '{print $1}' | xargs kill -9 2>/dev/null"

        @runner = ExternalServerRunner.new(configuration)
      end

      describe "#start" do
        it "stops the server, then starts an external rails server" do
          mock(runner).system(stop_server_cmd).ordered
          mock(runner).system(start_server_cmd).ordered
          runner.start
        end
      end

      describe "#stop" do
        it "stops the server" do
          mock(runner).system(stop_server_cmd).ordered
          runner.stop
        end
      end
    end
  end
end