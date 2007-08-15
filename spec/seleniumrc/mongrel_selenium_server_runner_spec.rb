require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

context "MongrelSeleniumServerRunner instance" do
  setup do
    @context = Seleniumrc::SeleniumContext.new
  end

  specify "starts server" do
    runner = create_runner_for_start_server
    stub(runner).initialize_server
    @runner.start
  end

  specify "start_server initializes server" do
    @runner = create_runner_for_start_server

    mock(@mock_configurator).listener.yields(@mock_configurator)

    stub(@runner).defaults.returns({:environment => ""})
    fake_rails = Object.new

    mock(@mock_configurator).rails.once.returns(fake_rails)
    mock(@mock_configurator).uri.with("/", {:handler => fake_rails})
    mock(@mock_configurator).load_plugins.once
    @runner.start
  end

  def create_runner_for_start_server
    @mock_configurator = mock_configurator = "mock_configurator"
    stub(@context).create_mongrel_configurator.returns(mock_configurator)
    @runner = @context.create_mongrel_runner

    mock(@mock_configurator).run
    stub(@mock_configurator).log
    mock(@mock_configurator).join

    mock_thread_class = "mock_thread_class"
    @runner.thread_class = mock_thread_class
    mock(mock_thread_class).start.yields
    @runner
  end
end