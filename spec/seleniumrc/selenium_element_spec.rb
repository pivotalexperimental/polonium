require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumElement, :shared => true do
  before do
    @element_locator = "id=foobar"
    @element = SeleniumElement.new(@element_locator)
  end
end

describe SeleniumElement, "#initialize" do
  it_should_behave_like "Seleniumrc::SeleniumElement"
  
  it "sets the locator" do
    @element.locator.should == @element_locator
  end
end

describe SeleniumElement, "#has_value" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  it "returns true when wait_for returns true" do
#    @element.has_value("joe")
  end
end
end
