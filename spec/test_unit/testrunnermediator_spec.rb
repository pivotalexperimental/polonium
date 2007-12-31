require File.expand_path("#{File.dirname(__FILE__)}/test_unit_spec_helper")

describe Test::Unit::UI::TestRunnerMediator do
  attr_reader :driver
  before do
    @driver = Polonium::Configuration.instance
  end

  it "start the server runner before suite and stops it after the suite" do
    suite = Test::Unit::TestSuite.new
    mediator = Test::Unit::UI::TestRunnerMediator.new(suite)

    runner = driver.create_server_runner
    mock(driver).create_server_runner {runner}
    mock(runner).stop
    mock(driver).stop_driver_if_necessary(true)
    mediator.run_suite
  end
end