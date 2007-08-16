require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumElement, :shared => true do
  include SeleniumTestCaseSpec
  
  before do
    @selenium = "Selenium"
    @element_locator ||= "id=foobar"
    @element = SeleniumElement.new(@selenium, @element_locator)
    stub_wait_for @element
  end
end

describe SeleniumElement, "#initialize" do
  it_should_behave_like "Seleniumrc::SeleniumElement"
  
  it "sets the locator" do
    @element.locator.should == @element_locator
  end

  it "sets the selenium object" do
    @element.selenium.should == @selenium
  end
end

describe SeleniumElement, "#is_present" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  it "passes when element is present" do
    ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      ticks.shift
    end.times(4)
    @element.is_present
  end
  
  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.is_present
    end.should raise_error("Expected element 'id=foobar' to be present, but it was not (after 5 sec)")
  end
end

describe SeleniumElement, "#has_value" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  it "passes when element is present and value is expected value" do
    mock(@selenium).is_element_present(@element_locator) {true}
    ticks = [nil, nil, nil, "joe"]
    mock(@selenium).get_value(@element_locator) do
      ticks.shift
    end.times(4)
    @element.has_value("joe")
  end

  it "fails when element is present and not expected value" do
    mock(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).get_value(@element_locator) {"jane"}
    proc do
      @element.has_value("joe")
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.has_value("joe")
    end.should raise_error
  end
end

describe SeleniumElement, "#has_attribute" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar@theattribute"
  end

  it "passes when element is present and value is expected value" do
    ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) {true}
    mock(@selenium).get_attribute(@element_locator) {"joe"}
    @element.has_attribute("joe")
  end

  it "fails when element is present and value is not expected" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).get_attribute(@element_locator) {"jane"}
    proc do
      @element.has_attribute("joe")
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.has_attribute("joe")
    end.should raise_error
  end
end

describe SeleniumElement, "#has_selected" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
  end

  it "passes when element is present and value is expected value" do
    ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) {true}
    mock(@selenium).get_selected_label(@element_locator) {"joe"}
    @element.has_selected("joe")
  end

  it "fails when element is present and value is not expected" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).get_selected_label(@element_locator) {"jane"}
    proc do
      @element.has_selected("joe")
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.has_selected("joe")
    end.should raise_error
  end
end
end
