require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumPage, :shared => true do
  include SeleniumTestCaseSpec
  
  before do
    @selenium = "Selenium"
    @page = SeleniumPage.new(@selenium)
  end
end

describe SeleniumPage, "#initialize" do
  it_should_behave_like "Seleniumrc::SeleniumPage"
  
  it "sets the selenium object" do
    @page.selenium.should == @selenium
  end
end

describe SeleniumPage, "#open_and_wait" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  it "opens the url and waits for the page to load" do
    mock(@selenium) do |o|
      o.open("/users/list")
      o.wait_for_page_to_load(@page.default_timeout)
      o.get_title {"Users in the project"}
    end
    @page.open_and_wait("/users/list")
  end

  it "fails when titles contains Exception caught" do
    mock(@selenium) do |o|
      o.open("/users/list")
      o.wait_for_page_to_load(@page.default_timeout)
      o.get_title {"Exception caught"}
    end
    proc do
      @page.open_and_wait("/users/list")
    end.should raise_error
  end
end

describe SeleniumPage, "#has_title" do
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

describe SeleniumPage, "#has_title?" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  it "returns true when passed in title is the page title" do
    mock(@selenium).get_title {"my page"}
    @page.has_title?("my page").should be_true
  end

  it "returns false when passed in title is not the page title" do
    mock(@selenium).get_title {"no page"}
    @page.has_title?("my page").should be_false
  end
end

describe SeleniumPage, "#is_text_present" do
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

describe SeleniumPage, "#is_text_present?" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  it "returns true when title is expected" do
    mock(@selenium).is_text_present("my page") {true}
    @page.is_text_present?("my page").should be_true
  end

  it "fails when element is not present" do
    mock(@selenium).is_text_present("my page") {false}
    @page.is_text_present?("my page").should be_false
  end
end

describe SeleniumPage, "#is_text_not_present" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  it "passes when text is not present" do
    ticks = [true, true, true, false]
    mock(@selenium).is_text_present("my page") do
      ticks.shift
    end.times(4)
    @page.is_text_not_present("my page")
  end

  it "fails when text is present" do
    stub(@selenium).is_text_present("my page") {true}
    proc do
      @page.is_text_not_present("my page")
    end.should raise_error("Expected 'my page' to be absent, but it wasn't (after 5 sec)")
  end
end

describe SeleniumPage, "#is_text_not_present?" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  it "returns true when text is not present" do
    mock(@selenium).is_text_present("my page") {false}
    @page.is_text_not_present?("my page").should be_true
  end

  it "returns false when text is present" do
    mock(@selenium).is_text_present("my page") {true}
    @page.is_text_not_present?("my page").should be_false
  end
end

describe SeleniumPage, "#url_ends_with" do
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

describe SeleniumPage, "#url_ends_with?" do
  it_should_behave_like "Seleniumrc::SeleniumPage"

  before do
    @ends_with = "foobar.com?arg1=2"
  end

  it "passes when title is expected" do
    mock(@selenium).get_location {"http://foobar.com?arg1=2"}
    @page.url_ends_with?(@ends_with).should be_true
  end

  it "fails when element is not present" do
    mock(@selenium).get_location {"http://no.com"}
    @page.url_ends_with?(@ends_with).should be_false
  end
end
end
