require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe Page, :shared => true do
    it_should_behave_like "Selenium"
    include TestCaseSpecHelper
    attr_reader :driver, :page, :element_locator

    before do
      @element_locator = "xpath=//body"
      @driver = ::Polonium::Driver.new('http://test.host', 4000, "*firefox", 'http://test.host')
      @page = Page.new(driver)
      page_loaded
    end

    def page_loaded
      stub(driver).get_eval(Page::PAGE_LOADED_COMMAND) {"true"}
    end

    def page_not_loaded
      stub(driver).get_eval(Page::PAGE_LOADED_COMMAND) {"false"}
    end
  end

  describe Page, "#initialize" do
    it_should_behave_like "Polonium::Page"

    it "sets the selenium object" do
      page.driver.should == driver
    end
  end

  describe Page, "#open_and_wait" do
    it_should_behave_like "Polonium::Page"

    it "opens the url and waits for the page to load" do
      mock(driver) do |m|
        m.do_command("open", ["/users/list"]) {result}
        m.do_command("waitForPageToLoad", [page.default_timeout]) do
          result
        end
        m.do_command("getTitle", []) do
          result("Users in the project")
        end
      end
      page.open_and_wait("/users/list")
    end

    it "fails when title contains 'Exception caught'" do
      mock(driver) do |m|
        m.do_command("open", ["/users/list"]) {result}
        m.do_command("waitForPageToLoad", [page.default_timeout]) do
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
        page.open_and_wait("/users/list")
      end.should raise_error(Test::Unit::AssertionFailedError)
    end
  end

  describe Page, "#assert_title" do
    it_should_behave_like "Polonium::Page"

    it "passes when title is expected" do
      ticks = ["no page", "no page", "no page", "my page"]
      mock(driver).get_title do
        ticks.shift
      end.times(4)
      mock.proxy(page).values_match?(/no page|my page/, "my page").times(4)

      page.assert_title("my page")
    end

    it "fails when element is not present" do
      stub(driver).get_title {"no page"}
      mock.proxy(page).values_match?("no page", "my page").times(4)

      proc do
        page.assert_title("my page")
      end.should raise_error("Expected title 'my page' but was 'no page' (after 5 sec)")
    end
  end

  describe Page, "#title" do
    it_should_behave_like "Polonium::Page"

    it "returns true when passed in title is the page title" do
      mock(driver).get_title {"my page"}
      page.title.should == "my page"
    end

    it "returns false when passed in title is not the page title" do
      mock(driver).get_title {"no page"}
      page.title.should_not == "my page"
    end
  end

  describe Page, "#assert_text_present" do
    it_should_behave_like "Polonium::Page"

    describe "when passed a String" do
      it "passes when page contains expected text" do
        get_text_ticks = [false, false, false, true]
        mock(driver).is_text_present("three") {get_text_ticks.shift}.times(4)
        
        page.assert_text_present("three")
      end

      it "fails when page does not contain expected text" do
        mock(driver).is_text_present("nowhere") {false}.times(4)

        lambda do
          page.assert_text_present("nowhere")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "when passed a Regexp" do
      it "passes when page contains expected text" do
        get_text_ticks = [false, false, false, true]
        mock(driver).is_text_present("regexp:three") {get_text_ticks.shift}.times(4)

        page.assert_text_present(/three/)
      end

      it "fails when page does not contain expected text" do
        mock(driver).is_text_present("regexp:nowhere") {false}.times(4)

        lambda do
          page.assert_text_present(/nowhere/)
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    it "fails when page is not loaded" do
      page_not_loaded
      proc do
        page.assert_text_present("my page")
      end.should raise_error("Expected 'my page' to be present, but it wasn't (after 5 sec)")
    end
  end

  describe Page, "#is_text_present?" do
    it_should_behave_like "Polonium::Page"

    it "returns true when text is present" do
      mock(driver).is_text_present("my page") {true}
      page.is_text_present?("my page").should be_true
    end
  end

  describe Page, "#assert_text_not_present" do
    it_should_behave_like "Polonium::Page"

    describe "when passed a String" do
      it "passes when page does not contain expected text" do
        mock(driver).is_text_present("match") {false}
        page.assert_text_not_present("match")
      end

      it "fails when page contains expected text for the entire wait_for period" do
        mock(driver).is_text_present("match") {true}.times(4)

        lambda do
          page.assert_text_not_present("match")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "when passed a Regexp" do
      it "passes when page does not contain expected text" do
        ticks = [true, true, true, false]
        mock(driver).is_text_present("regexp:match") {ticks.shift}.times(4)
        page.assert_text_not_present(/match/)
      end

      it "fails when page does contains expected text for the entire polling period" do
        mock(driver).is_text_present("regexp:match") {true}.times(4)

        lambda do
          page.assert_text_not_present(/match/)
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    it "fails when page is not loaded" do
      page_not_loaded
      proc do
        page.assert_text_present("my page")
      end.should raise_error("Expected 'my page' to be present, but it wasn't (after 5 sec)")
    end
  end

  describe Page, "#is_text_not_present?" do
    it_should_behave_like "Polonium::Page"

    it "returns true when text is not present" do
      mock(driver).is_text_present("your page") {false}
      page.is_text_not_present?("your page").should be_true
    end

    it "returns false when text is present" do
      mock(driver).is_text_present("my page") {true}
      page.is_text_not_present?("my page").should be_false
    end
  end

  describe Page, "#assert_location_ends_with" do
    it_should_behave_like "Polonium::Page"

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
      page.assert_location_ends_with(@ends_with)
    end

    it "fails when element is not present" do
      stub(driver).get_location {"http://no.com"}
      proc do
        page.assert_location_ends_with(@ends_with)
      end.should raise_error("Expected 'http://no.com' to end with '#{@ends_with}' (after 5 sec)")
    end
  end

  describe Page, "#location_ends_with?" do
    it_should_behave_like "Polonium::Page"

    before do
      @ends_with = "foobar.com?arg1=2"
    end

    it "passes when title is expected" do
      mock(driver).get_location {"http://foobar.com?arg1=2"}
      page.location_ends_with?(@ends_with).should be_true
    end

    it "fails when element is not present" do
      mock(driver).get_location {"http://no.com"}
      page.location_ends_with?(@ends_with).should be_false
    end
  end

  describe Page, "#page_loaded?" do
    it_should_behave_like "Polonium::Page"

    it "when page loaded command returns 'true', returns true" do
      page_loaded
      page.should be_page_loaded
    end

    it "when page loaded command returns 'false', returns false" do
      page_not_loaded
      page.should_not be_page_loaded
    end
  end

  describe Page, "#method_missing" do
    it_should_behave_like "Polonium::Page"

    it "delegates command to the driver" do
      page.methods.should_not include('get_location')
      mock(driver).get_location
      page.get_location
    end
  end
end
