require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe SeleniumDriver, :shared => true do
    it_should_behave_like "Selenium"
    attr_reader :driver, :commands
    before do
      @driver = ::Polonium::SeleniumDriver.new("localhost", 4444, "*iexplore", "localhost:3000")
    end

    def sample_locator
      "sample_locator"
    end

    def sample_text
      "test text"
    end
  end

  describe SeleniumDriver, "#initialize" do
    it_should_behave_like "Polonium::SeleniumDriver"
    
    it "initializes with defaults" do
      driver.server_host.should == "localhost"
      driver.server_port.should == 4444
      driver.browser_start_command.should == "*iexplore"
      driver.browser_url.should == "localhost:3000"
      driver.timeout_in_milliseconds.should == 30000
    end

    it "should start" do
      mock(driver).do_command.
        with("getNewBrowserSession", ["*iexplore", "localhost:3000"]).returns("   12345")

      driver.start
      driver.instance_variable_get(:@session_id).should == "12345"
    end
  end

  describe SeleniumDriver, "#inner_html_js" do
    it_should_behave_like "Polonium::SeleniumDriver"

    it "returns findElement command in js" do
      driver.inner_html_js(sample_locator).should ==
        %Q|this.page().findElement("#{sample_locator}").innerHTML|
    end
  end

  describe SeleniumDriver, "#wait_for_element_to_contain" do
    it_should_behave_like "Polonium::SeleniumDriver"

    it "when finding text within time limit, passes" do
      is_element_present_results = [false, true]
      mock(driver).do_command('isElementPresent', [sample_locator]).times(2) do
        result(is_element_present_results.shift)
      end
      mock(driver).do_command('getEval', [driver.inner_html_js(sample_locator)]) do
        result(sample_text)
      end

      driver.wait_for_element_to_contain(sample_locator, sample_text)
    end

    it "when element not found in time, fails" do
      mock(driver).do_command('isElementPresent', [sample_locator]).times(4) do
        result(false)
      end

      proc do
        driver.wait_for_element_to_contain(sample_locator, "")
      end.should raise_error(Test::Unit::AssertionFailedError, "Timeout exceeded (after 5 sec)")
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
        driver.wait_for_element_to_contain(sample_locator, "wrong text", nil, 1)
      end.should raise_error(Test::Unit::AssertionFailedError, "Timeout exceeded (after 1 sec)")
    end
  end

  describe SeleniumDriver, "#open and #open_and_wait" do
    it_should_behave_like "Polonium::SeleniumDriver"

    it "opens page and waits for it to load" do
      mock(driver).do_command("open", ["http://localhost:4000"])
      mock(driver).do_command("waitForPageToLoad", [driver.default_timeout]) {result}
      mock(driver).do_command("getTitle", []) {result("Some Title")}

      driver.open("http://localhost:4000")
    end

    it "aliases #open_and_wait to #open" do
      driver.method(:open_and_wait).should == driver.method(:open)
    end
  end  
end
