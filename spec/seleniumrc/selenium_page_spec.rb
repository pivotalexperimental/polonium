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

describe SeleniumElement, "#is_text_present" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  it "passes when title is expected" do
    ticks = [false, false, false, true]
    mock(@selenium).is_text_present("my page") do
      ticks.shift
    end.times(4)
    @page.is_text_present("my page")
  end

  it "fails when element is not present" do
    stub(@selenium).is_text_present("my page") {false}
    proc do
      @page.is_text_present("my page")
    end.should raise_error("Expected 'my page' to be present, but it wasn't (after 5 sec)")
  end
end

describe SeleniumElement, "#is_text_not_present" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  it "passes when title is expected" do
    ticks = [true, true, true, false]
    mock(@selenium).is_text_present("my page") do
      ticks.shift
    end.times(4)
    @page.is_text_not_present("my page")
  end

  it "fails when element is not present" do
    stub(@selenium).is_text_present("my page") {true}
    proc do
      @page.is_text_not_present("my page")
    end.should raise_error("Expected 'my page' to be absent, but it wasn't (after 5 sec)")
  end
end

describe SeleniumElement, "#url_ends_with" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  before do
    @ends_with = "foobar.com?arg1=2"
  end

  it "passes when title is expected" do
    ticks = [
      "http://no.com",
      "http://no.com",
      "http://no.com",
      "http://foobar.com?arg1=2"
    ]
    mock(@selenium).get_location do
      ticks.shift
    end.times(4)
    @page.url_ends_with(@ends_with)
  end

  it "fails when element is not present" do
    stub(@selenium).get_location {"http://no.com"}
    proc do
      @page.url_ends_with(@ends_with)
    end.should raise_error("Expected 'http://no.com' to end with '#{@ends_with}' (after 5 sec)")
  end
end
end
