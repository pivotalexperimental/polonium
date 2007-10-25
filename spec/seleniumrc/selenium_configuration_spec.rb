require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumConfiguration do
  before(:each) do
    SeleniumConfiguration.instance_eval {@context = nil}
    @mock_context = SeleniumContext.new
  end

  it "should create a new context if it hasn't been called yet" do
    mock(SeleniumContext).new.returns(@mock_context)
    SeleniumConfiguration.instance.should == @mock_context
  end

  it "should reuse the existing context if it has been called.  So new/establish_environment should only be called once." do
    mock(SeleniumContext).new.returns(@mock_context)
    SeleniumConfiguration.instance.should == @mock_context
    SeleniumConfiguration.instance.should == @mock_context
  end
end
end
