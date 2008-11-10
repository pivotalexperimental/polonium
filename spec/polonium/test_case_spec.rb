require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe TestCase do
    it_should_behave_like "Selenium"
    include TestCaseSpecHelper
    attr_reader :driver, :test_case, :configuration

    before(:each) do
      @original_configuration = Configuration.instance
      stub_selenium_configuration
      @test_case = TestCaseSpecHelper::MySeleniumTestCase.new
      @driver = ::Polonium::Driver.new('http://test.host', 4000, "*firefox", 'http://test.host')
      test_case.selenium_driver = driver
      stub(driver).do_command("getEval", [Page::PAGE_LOADED_COMMAND]) do
        result(true)
      end
    end

    after(:each) do
      Configuration.instance = @original_configuration
    end

    def sample_locator
      "sample_locator"
    end

    def sample_text
      "test text"
    end

    def stub_selenium_configuration
      @configuration = Configuration.new
      configuration.external_app_server_host = "test.com"
      configuration.external_app_server_port = 80

      stub(Configuration.instance) {configuration}
    end    

    describe "#setup" do
      it "should not allow transactional fixtures" do
        test_case.class.use_transactional_fixtures = true

        expected_message = "Cannot use transactional fixtures if ActiveRecord concurrency is turned on (which is required for Selenium tests to work)."
        proc do
          test_case.setup
        end.should raise_error(RuntimeError, expected_message)
      end
    end

    describe "#wait_for" do
      describe "when the block returns true within time limit" do
        it "does not raise an error" do
          test_case.wait_for(:timeout => 2) do
            true
          end
        end

        it "returns the value of the evaluated block" do
          test_case.wait_for(:timeout => 2) do
            99
          end.should == 99
        end
      end

      describe "when block times out" do
        it "raises a AssertionFailedError" do
          proc do
            test_case.wait_for(:timeout => 2) {false}
          end.should raise_error(PoloniumError, "Timeout exceeded (after 2 sec)")
        end
      end
    end

    describe "#default_timeout" do
      it "default_timeout should be 20 seconds" do
        test_case.default_timeout.should == 20000
      end
    end

    describe "#open_home_page" do
      it "opens home page" do
        mock(driver).open("http://127.0.0.1:4000")
        test_case.open_home_page
      end
    end

    describe "#assert_title" do
      it "when title is expected, passes" do
        mock(driver).do_command("getTitle", []) {result("my page")}
        test_case.assert_title("my page")
      end

      it "when title is not expected, fails" do
        stub(driver).do_command("getTitle", []) {result("no page")}
        proc do
          test_case.assert_title("my page")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_text_present" do
      before do
        mock.proxy(Page).new(driver) do |page|
          mock.proxy(page).assert_text_present("my page", {})
          page
        end
      end

      it "passes when text is in page" do
        ticks = [false, false, false, true]
        mock(driver).is_text_present("my page") do
          ticks.shift
        end.times(4)
        test_case.assert_text_present("my page")
      end

      it "fails when text is not in page" do
        stub(driver).is_text_present("my page") {false}
        proc do
          test_case.assert_text_present("my page")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_text_not_present" do
      before do
        mock.proxy(Page).new(driver) do |page|
          mock.proxy(page).assert_text_not_present("my page", {})
          page
        end
      end

      it "passes when text is not in page" do
        ticks = [true, true, true, false]
        mock(driver).is_text_present("my page") do
          ticks.shift
        end.times(4)
        test_case.assert_text_not_present("my page")
      end

      it "fails when text is in page" do
        stub(driver).is_text_present("my page") {true}
        proc do
          test_case.assert_text_not_present("my page")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_location_ends_with" do
      before do
        @ends_with = "foobar.com?arg1=2"
        mock.proxy(Page).new(driver) do |page|
          mock.proxy(page).assert_location_ends_with(@ends_with, {})
          page
        end
      end

      it "passes when the url ends with the passed in value" do
        ticks = [
          "http://no.com",
            "http://no.com",
            "http://no.com",
            "http://foobar.com?arg1=2"
        ]
        mock(driver).get_location do
          ticks.shift
        end.times(4)
        test_case.assert_location_ends_with(@ends_with)
      end

      it "fails when the url does not end with the passed in value" do
        stub(driver).get_location {"http://no.com"}
        proc do
          test_case.assert_location_ends_with(@ends_with)
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_element_present" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_element_present
          element
        end
      end

      it "passes when element is present" do
        ticks = [false, false, false, true]
        mock(driver).do_command("isElementPresent", [sample_locator]).times(4) do
          result(ticks.shift)
        end
        test_case.assert_element_present(sample_locator)
      end

      it "fails when element is not present" do
        stub(driver).do_command("isElementPresent", [sample_locator]) do
          result(false)
        end
        proc do
          test_case.assert_element_present(sample_locator)
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_element_not_present" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_element_not_present
          element
        end
      end

      it "passes when element is not present" do
        ticks = [true, true, true, false]
        mock(driver) do |o|
          o.is_element_present(sample_locator) do
            ticks.shift
          end.times(4)
        end
        test_case.assert_element_not_present(sample_locator)
      end

      it "fails when element is present" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
        end
        proc do
          test_case.assert_element_not_present(sample_locator)
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_value" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_value("passed in value")
          element
        end
      end

      it "passes when value is expected" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_value(sample_locator) {"passed in value"}
        end
        test_case.assert_value(sample_locator, "passed in value")
      end

      it "fails when value is not expected" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_value(sample_locator) {"another value"}
        end
        proc do
          test_case.assert_value(sample_locator, "passed in value")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_element_contains" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_contains("passed in value", {})
          element
        end
        @evaled_js = "this.page().findElement(\"#{sample_locator}\").innerHTML"
      end

      it "passes when text is in the element's inner_html" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_eval(@evaled_js) do
            "html passed in value html"
          end
        end
        test_case.assert_element_contains(sample_locator, "passed in value")
      end

      it "fails when text is not in the element's inner_html" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_eval(@evaled_js) {"another value"}
        end
        proc do
          test_case.assert_element_contains(sample_locator, "passed in value")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#element_does_not_contain_text" do
      it "when element is not on the page, returns true" do
        locator = "id=element_id"
        expected_text = "foobar"
        mock(driver).is_element_present(locator) {false}

        test_case.element_does_not_contain_text(locator, expected_text).should == true
      end

      it "when element is on page and inner_html does not contain text, returns true" do
        locator = "id=element_id"
        inner_html = "Some text that does not contain the expected_text"
        expected_text = "foobar"
        mock(driver).do_command("isElementPresent", [locator]) do
          result(true)
        end
        mock(driver).do_command("getEval", [driver.inner_html_js(locator)]) do
          inner_html
        end

        test_case.element_does_not_contain_text(locator, expected_text).should == true
      end

      it "when element is on page and inner_html does contain text, returns false" do
        locator = "id=element_id"
        inner_html = "foobar foobar foobar"
        expected_text = "foobar"
        mock(driver).do_command("isElementPresent", [locator]) do
          result(true)
        end
        mock(driver).do_command("getEval", [driver.inner_html_js(locator)]) do
          inner_html
        end

        test_case.element_does_not_contain_text(locator, expected_text).should == false
      end
    end

    describe "#assert_element_does_not_contain" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_does_not_contain("passed in value", {})
          element
        end
        @evaled_js = "this.page().findElement(\"#{sample_locator}\").innerHTML"
      end

      it "passes when text is not in the element's inner_html" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_eval(@evaled_js) do
            "another value"
          end
        end
        test_case.assert_element_does_not_contain(sample_locator, "passed in value")
      end

      it "fails when text is in the element's inner_html" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_eval(@evaled_js) {"html passed in value html"}
        end
        proc do
          test_case.assert_element_does_not_contain(sample_locator, "passed in value")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_contains_in_order" do
      it "when text is in order, it succeeds" do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_contains_in_order("one", "two", "three")
          element
        end
        stub(@driver).get_text(sample_locator).returns("one\ntwo\nthree\n")
        stub(@driver).is_element_present(sample_locator) {true}

        test_case.assert_contains_in_order sample_locator, "one", "two", "three"
      end
    end

    describe "#assert_attribute" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_attribute('id', "passed in value")
          element
        end
      end

      it "passes when attribute is expected" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_attribute("#{sample_locator}@id") {"passed in value"}
        end
        test_case.assert_attribute(sample_locator, 'id', "passed in value")
      end

      it "fails when attribute is not expected" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_attribute("#{sample_locator}@id") {"another value"}
        end
        proc do
          test_case.assert_attribute(sample_locator, 'id', "passed in value")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_selected" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_selected("passed_in_element")
          element
        end
      end

      it "passes when selected is expected" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_selected_label(sample_locator) {"passed_in_element"}
        end
        test_case.assert_selected(sample_locator, "passed_in_element")
      end

      it "fails when selected is not expected" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_selected_label(sample_locator) {"another_element"}
        end
        proc do
          test_case.assert_selected(sample_locator, "passed_in_element")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_checked" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_checked
          element
        end
      end

      it "passes when checked" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.is_checked(sample_locator) {true}
        end
        test_case.assert_checked(sample_locator)
      end

      it "fails when not checked" do
        stub(driver) do |driver|
          driver.is_element_present(sample_locator) {true}
          driver.is_checked(sample_locator) {false}
        end
        proc do
          test_case.assert_checked(sample_locator)
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_not_checked" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_not_checked
          element
        end
      end

      it "passes when not checked" do
        mock(driver) do |driver|
          driver.is_element_present(sample_locator) {true}
          driver.is_checked(sample_locator) {false}
        end
        test_case.assert_not_checked(sample_locator)
      end

      it "fails when checked" do
        stub(driver) do |driver|
          driver.is_element_present(sample_locator) {true}
          driver.is_checked(sample_locator) {true}
        end
        proc do
          test_case.assert_not_checked(sample_locator)
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_text" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_text("expected text")
          element
        end
      end

      it "passes when text is expected" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_text(sample_locator) {"expected text"}
        end
        test_case.assert_text(sample_locator, "expected text")
      end

      it "fails when text is not expected" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_text(sample_locator) {"unexpected text"}
        end
        proc do
          test_case.assert_text(sample_locator, "expected text")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_visible" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_visible
          element
        end
      end

      it "passes when element is visible" do
        mock(driver).is_element_present(sample_locator) {true}
        mock(driver).is_visible(sample_locator) {true}

        test_case.assert_visible(sample_locator)
      end

      it "fails when element is not visible" do
        stub(driver).is_element_present(sample_locator) {true}
        stub(driver).is_visible.returns {false}

        proc {
          test_case.assert_visible(sample_locator)
        }.should raise_error(PoloniumError)
      end
    end

    describe "#assert_not_visible" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_not_visible
          element
        end
      end

      it "passes when element is present and is not visible" do
        mock(driver).is_element_present(sample_locator) {true}
        mock(driver).is_visible(sample_locator) {false}

        test_case.assert_not_visible(sample_locator)
      end

      it "fails when element is visible" do
        stub(driver).is_element_present(sample_locator) {true}
        stub(driver).is_visible(sample_locator) {true}

        proc {
          test_case.assert_not_visible(sample_locator)
        }.should raise_error(PoloniumError)
      end
    end

    describe "#assert_next_sibling" do
      before do
        mock.proxy(Element).new(driver, sample_locator) do |element|
          mock.proxy(element).assert_next_sibling("next_sibling")
          element
        end
        @evaled_js = "this.page().findElement('#{sample_locator}').nextSibling.id"
      end

      it "passes when passed next sibling id" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_eval(@evaled_js) {"next_sibling"}
        end
        test_case.assert_next_sibling(sample_locator, "next_sibling")
      end

      it "fails when not passed next sibling id" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_eval(@evaled_js) {"wrong_sibling"}
        end
        proc do
          test_case.assert_next_sibling(sample_locator, "next_sibling")
        end.should raise_error(PoloniumError)
      end
    end

    describe "#assert_contains_in_order" do
      before do
        mock.proxy(Element).new(driver, sample_locator)
        @evaled_js = "this.page().findElement('#{sample_locator}').nextSibling.id"
      end

      it "passes when text is in order" do
        mock(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_text(sample_locator) {"one\ntwo\nthree\n"}
        end
        test_case.assert_contains_in_order sample_locator, "one", "two", "three"
      end

      it "fails when element is present and text is not in order" do
        stub(driver) do |o|
          o.is_element_present(sample_locator) {true}
          o.get_text(sample_locator) {"<html>one\ntext not in order\n</html>"}
        end
        proc do
          test_case.assert_contains_in_order sample_locator, "one", "two", "three"
        end.should raise_error(PoloniumError)
      end
    end

    describe "#page" do
      it "returns page" do
        test_case.page.should == Page.new(driver)
      end
    end

    describe "#get_eval" do
      it "delegates to Driver" do
        mock(driver).get_eval "foobar"
        test_case.get_eval "foobar"
      end
    end

    describe "#assert_element_contains" do
      it "when finding text within time limit, passes" do
        is_element_present_results = [false, true]
        mock(driver).do_command('isElementPresent', [sample_locator]).times(2) do
          result(is_element_present_results.shift)
        end
        mock(driver).do_command('getEval', [driver.inner_html_js(sample_locator)]) do
          result(sample_text)
        end

        test_case.assert_element_contains(sample_locator, sample_text)
      end

      it "when element not found in time, fails" do
        mock(driver).do_command('isElementPresent', [sample_locator]).times(4) do
          result(false)
        end

        proc do
          test_case.assert_element_contains(sample_locator, "")
        end.should raise_error(PoloniumError, "Expected element 'sample_locator' to be present, but it was not (after 5 sec)")
      end

      it "when text does not match in time, fails" do
        is_element_present_results = [false, true, true, true]
        stub(driver).do_command('isElementPresent', [sample_locator]) do
          result(is_element_present_results.shift)
        end
        stub(driver).do_command('getEval', [driver.inner_html_js(sample_locator)]) do
          result(sample_text)
        end

        proc do
          test_case.assert_element_contains(sample_locator, "wrong text")
        end.should raise_error(PoloniumError, "sample_locator should contain wrong text (after 5 sec)")
      end
    end

    describe "#method_missing" do
      describe "when the #selenium_driver responds to the method" do
        before do
          driver.respond_to?(:assert_element_present).should be_true
        end

        it "delegates the invocation to the selenium_driver" do
          mock(driver).assert_element_present("id=element", {})
          test_case.assert_element_present("id=element", {})
        end
      end

      describe "when the #selenium_driver does not respond to the method" do
        before do
          driver.respond_to?(:another_method).should_not be_true
        end

        it "handles invokes the superclass method_missing" do
          lambda do
            test_case.another_method
          end.should raise_error(NoMethodError, /TestCaseSpecHelper::MySeleniumTestCase/)
        end
      end
    end

    describe "when in test browser mode" do
      describe "and test fails" do
        it "should stop driver when configuration says to stop test" do
          Configuration.instance = configuration = Polonium::Configuration.new
          configuration.test_browser_mode

          stub(test_case).passed? {false}
          configuration.keep_browser_open_on_failure = false

          mock(driver).stop.once
          test_case.selenium_driver = driver

          test_case.teardown
        end

        it "should not stop driver when configuration says not to stop test" do
          Configuration.instance = "Polonium::Configuration"
          mock(Configuration.instance).test_browser_mode?.returns(true)

          stub(test_case).passed? {false}
          mock(Configuration.instance).stop_driver?(false) {false}

          test_case.selenium_driver = driver

          test_case.teardown
        end
      end

      describe "and test passes" do
        it "should stop driver when configuration says to stop test" do
          Configuration.instance = "Polonium::Configuration"
          mock(Configuration.instance).test_browser_mode?.returns(true)

          stub(test_case).passed?.returns(true)
          mock(Configuration.instance).stop_driver?(true) {true}

          mock(driver).stop.once
          test_case.selenium_driver = driver

          test_case.teardown
        end

        it "should not stop driver when configuration says not to stop test" do
          Configuration.instance = "Polonium::Configuration"
          mock(Configuration.instance).test_browser_mode?.returns(true)

          stub(test_case).passed?.returns(true)
          mock(Configuration.instance).stop_driver?(true) {false}

          test_case.selenium_driver = driver

          test_case.teardown
        end
      end
    end

    describe "when in suite browser mode" do
      it "should not stop driver when tests fail" do
        Configuration.instance = "Polonium::Configuration"
        mock(Configuration.instance).test_browser_mode? {false}

        def test_case.passed?;
          false;
        end

        test_case.selenium_driver = driver

        test_case.teardown
      end

      it "should stop driver when tests pass" do
        Configuration.instance = "Polonium::Configuration"
        mock(Configuration.instance).test_browser_mode? {false}

        stub(test_case).passed?.returns(true)

        test_case.selenium_driver = driver

        test_case.teardown
      end
    end
  end
end
