require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
  describe MongrelSeleniumServerRunner, "#start_server" do
    attr_reader :configuration
    before do
      @configuration = SeleniumConfiguration.new
    end

    it "initializes server and runs app_server_initialization callback" do
      mongrel_configurator = configuration.create_mongrel_configurator
      stub(configuration).create_mongrel_configurator {mongrel_configurator}
      mock(mongrel_configurator).run
      stub(mongrel_configurator).log
      mock(mongrel_configurator).join
      fake_rails = "fake rails"
      mock(mongrel_configurator).rails {fake_rails}
      mock(mongrel_configurator).uri("/", {:handler => fake_rails})
      mock(mongrel_configurator).load_plugins
      mock(mongrel_configurator).listener.yields(mongrel_configurator)

      callback_mongrel = nil
      configuration.app_server_initialization = proc do |mongrel|
        callback_mongrel = mongrel
      end
      runner = configuration.create_mongrel_runner
      stub(runner).defaults do; {:environment => ""}; end
      runner.thread_class = mock_thread_class = "mock_thread_class"
      mock(mock_thread_class).start.yields

      runner.start
      callback_mongrel.should == mongrel_configurator
    end
  end
end