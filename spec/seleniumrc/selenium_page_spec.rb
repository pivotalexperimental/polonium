require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe SeleniumPage, :shared => true do
    it_should_behave_like "Selenium"
    include SeleniumTestCaseSpec
    attr_reader :driver

    before do
      @driver = ::Polonium::SeleniumDriver.new('http://test.host', 4000, "*firefox", 'http://test.host')
      @page = SeleniumPage.new(driver)
      page_loaded
    end

    def page_loaded
      stub(driver).get_eval(SeleniumPage::PAGE_LOADED_COMMAND) {"true"}
    end

    def page_not_loaded
      stub(driver).get_eval(SeleniumPage::PAGE_LOADED_COMMAND) {"false"}
    end
  end

  describe SeleniumPage, "#initialize" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "sets the selenium object" do
      @page.driver.should == driver
    end
  end

  describe SeleniumPage, "#open_and_wait" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "opens the url and waits for the page to load" do
      mock(driver) do |m|
        m.do_command("open", ["/users/list"]) {result}
        m.do_command("waitForPageToLoad", [@page.default_timeout]) do
          result
        end
        m.do_command("getTitle", []) do
          result("Users in the project")
        end
      end
      @page.open_and_wait("/users/list")
    end

    it "fails when title contains 'Exception caught'" do
      mock(driver) do |m|
        m.do_command("open", ["/users/list"]) {result}
        m.do_command("waitForPageToLoad", [@page.default_timeout]) do
          result
        end
        m.do_command("getTitle", []) do
          result("Exception caught")
        end
        m.do_command("getHtmlSource", []) do
          result("The page's html")
        end
      end
      proc do
        @page.open_and_wait("/users/list")
      end.should raise_error(Test::Unit::AssertionFailedError)
    end
  end

  describe SeleniumPage, "#has_title" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "passes when title is expected" do
      ticks = ["no page", "no page", "no page", "my page"]
      mock(driver).get_title do
        ticks.shift
      end.times(4)
      @page.assert_title("my page")
    end

    it "fails when element is not present" do
      stub(driver).get_title {"no page"}
      proc do
        @page.assert_title("my page")
      end.should raise_error("Expected title 'my page' but was 'no page' (after 5 sec)")
    end
  end

  describe SeleniumPage, "#title" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "returns true when passed in title is the page title" do
      mock(driver).get_title {"my page"}
      @page.title.should == "my page"
    end

    it "returns false when passed in title is not the page title" do
      mock(driver).get_title {"no page"}
      @page.title.should_not == "my page"
    end
  end

  describe SeleniumPage, "#assert_text_present" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "passes when title is expected" do
      ticks = [false, false, false, true]
      mock(driver).is_text_present("my page") do
        ticks.shift
      end.times(4)
      @page.assert_text_present("my page")
    end

    it "fails when page is not loaded" do
      page_not_loaded
      proc do
        @page.assert_text_present("my page")
      end.should raise_error("Expected 'my page' to be present, but it wasn't (after 5 sec)")
    end

    it "fails when element is not present" do
      stub(driver).is_text_present("my page") {false}
      proc do
        @page.assert_text_present("my page")
      end.should raise_error("Expected 'my page' to be present, but it wasn't (after 5 sec)")
    end
  end

  describe SeleniumPage, "#is_text_present?" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "returns true when title is expected" do
      mock(driver).is_text_present("my page") {true}
      @page.is_text_present?("my page").should be_true
    end

    it "fails when element is not present" do
      mock(driver).is_text_present("my page") {false}
      @page.is_text_present?("my page").should be_false
    end
  end

  describe SeleniumPage, "#is_text_not_present" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "passes when text is not present" do
      ticks = [true, true, true, false]
      mock(driver).is_text_present("my page") do
        ticks.shift
      end.times(4)
      @page.assert_text_not_present("my page")
    end

    it "fails when page not loaded" do
      page_not_loaded
      proc do
        @page.assert_text_not_present("my page")
      end.should raise_error("Expected 'my page' to be absent, but it wasn't (after 5 sec)")
    end

    it "fails when text is present" do
      stub(driver).is_text_present("my page") {true}
      proc do
        @page.assert_text_not_present("my page")
      end.should raise_error("Expected 'my page' to be absent, but it wasn't (after 5 sec)")
    end
  end

  describe SeleniumPage, "#is_text_not_present?" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "returns true when text is not present" do
      mock(driver).is_text_present("my page") {false}
      @page.is_text_not_present?("my page").should be_true
    end

    it "returns false when text is present" do
      mock(driver).is_text_present("my page") {true}
      @page.is_text_not_present?("my page").should be_false
    end
  end

  describe SeleniumPage, "#assert_location_ends_with" do
    it_should_behave_like "Polonium::SeleniumPage"

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
      mock(driver).get_location do
        ticks.shift
      end.times(4)
      @page.assert_location_ends_with(@ends_with)
    end

    it "fails when element is not present" do
      stub(driver).get_location {"http://no.com"}
      proc do
        @page.assert_location_ends_with(@ends_with)
      end.should raise_error("Expected 'http://no.com' to end with '#{@ends_with}' (after 5 sec)")
    end
  end

  describe SeleniumPage, "#location_ends_with?" do
    it_should_behave_like "Polonium::SeleniumPage"

    before do
      @ends_with = "foobar.com?arg1=2"
    end

    it "passes when title is expected" do
      mock(driver).get_location {"http://foobar.com?arg1=2"}
      @page.location_ends_with?(@ends_with).should be_true
    end

    it "fails when element is not present" do
      mock(driver).get_location {"http://no.com"}
      @page.location_ends_with?(@ends_with).should be_false
    end
  end

  describe SeleniumPage, "#page_loaded?" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "when page loaded command returns 'true', returns true" do
      page_loaded
      @page.should be_page_loaded
    end

    it "when page loaded command returns 'false', returns false" do
      page_not_loaded
      @page.should_not be_page_loaded
    end
  end

  describe SeleniumPage, "#method_missing" do
    it_should_behave_like "Polonium::SeleniumPage"

    it "delegates command to the driver" do
      @page.methods.should_not include('get_location')
      mock(driver).get_location
      @page.get_location
    end
  end
end
