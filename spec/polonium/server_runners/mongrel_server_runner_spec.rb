require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

module Polonium
  module ServerRunners
    describe MongrelServerRunner do
    describe "#start_server" do
      attr_reader :configuration
      before do
        @configuration = Configuration.new
      end

      it "initializes server and runs app_server_initialization callback" do
        runner = MongrelServerRunner.new(configuration)

        fake_rails = "fake rails"
        mongrel_configurator = nil
        mock.proxy(runner).create_mongrel_configurator do |mongrel_configurator|
          mongrel_configurator = mongrel_configurator
          stub(configuration).create_mongrel_configurator {mongrel_configurator}
          mock(mongrel_configurator).run
          stub(mongrel_configurator).log
          mock(mongrel_configurator).join
          mock(mongrel_configurator).rails {fake_rails}
          mock(mongrel_configurator).uri("/", {:handler => fake_rails})
          mock(mongrel_configurator).load_plugins
          mock(mongrel_configurator).listener.yields(mongrel_configurator)
          mongrel_configurator
        end

        callback_mongrel = nil
        configuration.app_server_initialization = proc do |mongrel|
          callback_mongrel = mongrel
        end
        stub(runner).defaults do; {:environment => ""}; end
        mock(Thread).start.yields

        runner.start
        callback_mongrel.should == mongrel_configurator
      end

      describe "#create_mongrel_configurator" do
        it "creates Mongrel configurator" do
          configuration.internal_app_server_host = "localhost"
          configuration.internal_app_server_port = 4000
          configuration.rails_env = "test"
          configuration.rails_root = rails_root = File.dirname(__FILE__)

          runner = MongrelServerRunner.new(configuration)
          configurator = runner.send(:create_mongrel_configurator)
          configurator.defaults[:host].should == "localhost"
          configurator.defaults[:port].should == 4000
          configurator.defaults[:cwd].should == configuration.rails_root
          configurator.defaults[:log_file].should == "#{configuration.rails_root}/log/mongrel.log"
          configurator.defaults[:pid_file].should == "#{configuration.rails_root}/log/mongrel.pid"
          configurator.defaults[:environment].should == "test"
          configurator.defaults[:docroot].should == "#{rails_root}/public"
          configurator.defaults[:mime_map].should be_nil
          configurator.defaults[:daemon].should == false
          configurator.defaults[:debug].should == false
          configurator.defaults[:includes].should == ["mongrel"]
          configurator.defaults[:config_script].should be_nil
        end
      end
    end
  end
  end
end