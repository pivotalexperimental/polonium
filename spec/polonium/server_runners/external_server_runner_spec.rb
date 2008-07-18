require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

module Polonium
  module ServerRunners
    describe ExternalServerRunner do
      attr_reader :configuration, :rails_env, :rails_root, :runner, :start_server_command, :stop_server_command, :original_start_server_command, :original_stop_server_command
      before do
        @configuration = Configuration.new
        @rails_env = configuration.rails_env = 'test'
        @rails_root = configuration.rails_root = File.dirname(__FILE__)

        @start_server_command = "cd #{rails_root}; script/server -e #{rails_env} -p #{configuration.internal_app_server_port} -c #{rails_root}"
        @stop_server_command = "ps ax | grep 'script/server -e #{rails_env}' | sed /grep/d | awk '{print $1}' | xargs kill -9 2>/dev/null"

        @runner = ExternalServerRunner.new(configuration)
      end

      after do
        ExternalServerRunner.start_server_command(&ExternalServerRunner::DEFAULT_START_SERVER_COMMAND)
        ExternalServerRunner.stop_server_command(&ExternalServerRunner::DEFAULT_STOP_SERVER_COMMAND)
      end

      describe "#start" do
        it "stops the server, then starts an external rails server" do
          mock(runner).system(stop_server_command).ordered
          mock(runner).system(start_server_command).ordered
          runner.start
        end

        context "with a custom start_server_command" do
          it "stops the server, then starts an external rails server with the custom command" do
            ExternalServerRunner.start_server_command do
              "custom start server command"
            end

            mock(runner).system(stop_server_command).ordered
            mock(runner).system("custom start server command").ordered
            runner.start
          end
        end

        context "with a custom stop_server_command" do
          it "stops the server with the custom command, then starts an external rails server" do
            ExternalServerRunner.stop_server_command do
              "custom stop server command"
            end

            mock(runner).system("custom stop server command").ordered
            mock(runner).system(start_server_command).ordered
            runner.start
          end
        end
      end

      describe "#stop" do
        it "stops the server" do
          mock(runner).system(stop_server_command)
          runner.stop
        end

        context "with a custom stop_server_command" do
          it "stops the server with the custom command" do
            ExternalServerRunner.stop_server_command do
              "custom stop server command"
            end

            mock(runner).system("custom stop server command")
            runner.stop
          end
        end
      end
    end
  end
end