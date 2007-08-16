require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumPage, :shared => true do
  include SeleniumTestCaseSpec
  
  before do
    @selenium = "Selenium"
    @page = SeleniumPage.new(@selenium)
    stub_wait_for @page
  end
end

describe SeleniumElement, "#initialize" do
  it_should_behave_like "Seleniumrc::SeleniumPage"
  
  it "sets the selenium object" do
    @page.selenium.should == @selenium
  end
end

describe SeleniumElement, "#has_title" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  it "passes when title is expected" do
    ticks = ["no page", "no page", "no page", "my page"]
    mock(@selenium).get_title do
      ticks.shift
    end.times(4)
    @page.has_title("my page")
  end

  it "fails when element is not present" do
    stub(@selenium).get_title {"no page"}
    proc do
      @page.has_title("my page")
    end.should raise_error("Expected title 'my page' but was 'no page' (after 5 sec)")
  end
end
end
