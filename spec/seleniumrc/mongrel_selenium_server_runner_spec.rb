require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
  context MongrelSeleniumServerRunner, "#start_server" do
    before do
      @context = SeleniumConfiguration.new
    end

    it "initializes server and runs app_server_initialization callback" do
      configurator = @context.create_mongrel_configurator
      stub(@context).create_mongrel_configurator.returns(configurator)
      mock(configurator).run
      stub(configurator).log
      mock(configurator).join
      fake_rails = "fake rails"
      mock(configurator).rails.returns(fake_rails)
      mock(configurator).uri.with("/", {:handler => fake_rails})
      mock(configurator).load_plugins.once
      mock(configurator).listener.yields(configurator)

      callback_mongrel = nil
      @context.app_server_initialization = proc do |mongrel|
        callback_mongrel = mongrel
      end
      runner = @context.create_mongrel_runner
      stub(runner).defaults.returns({:environment => ""})
      runner.thread_class = mock_thread_class = "mock_thread_class"
      mock(mock_thread_class).start.yields

      runner.start
      callback_mongrel.should == configurator
    end
  end
end