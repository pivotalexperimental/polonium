require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumDriver do
  it "initializes with defaults" do
    @driver = SeleniumDriver.new("localhost", 4444, "*iexplore", "localhost:3000")

    @driver.server_host.should == "localhost"
    @driver.server_port.should == 4444
    @driver.browser_start_command.should == "*iexplore"
    @driver.browser_url.should == "localhost:3000"
    @driver.timeout_in_milliseconds.should == 30000
  end

  it "should start" do
    @driver = SeleniumDriver.new("localhost", 4444, "*iexplore", "localhost:3000")

    mock(@driver).do_command.
      with("getNewBrowserSession", ["*iexplore", "localhost:3000"]).returns("   12345")

    @driver.start
    @driver.instance_eval {@session_id}.should == "12345"
  end
end
end
