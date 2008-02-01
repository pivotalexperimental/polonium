require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe Driver do
    it_should_behave_like "Selenium"
    attr_reader :driver, :commands
    before do
      @driver = ::Polonium::Driver.new("localhost", 4444, "*iexplore", "localhost:3000")
    end

    def sample_locator
      "sample_locator"
    end

    def sample_text
      "test text"
    end

    describe "#initialize" do
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

    describe "#inner_html_js" do
      it "returns findElement command in js" do
        driver.inner_html_js(sample_locator).should ==
          %Q|this.page().findElement("#{sample_locator}").innerHTML|
      end
    end

    describe "#open and #open_and_wait" do
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

    describe "#type" do
      it "types when element is present and types" do
        is_element_present_results = [false, true]
        mock(driver).do_command("isElementPresent", ["id=foobar"]).twice do
          result(is_element_present_results.shift)
        end
        mock(driver).do_command("type", ["id=foobar", "The Text"]) do
          result()
        end

        driver.type "id=foobar", "The Text"
      end

      it "fails when element is not present" do
        mock(driver).do_command("isElementPresent", ["id=foobar"]).times(4) do
          result(false)
        end
        dont_allow(driver).do_command("type", ["id=foobar", "The Text"])

        proc {
          driver.type "id=foobar", "The Text"
        }.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#click" do
      it "click when element is present and types" do
        is_element_present_results = [false, true]
        mock(driver).do_command("isElementPresent", ["id=foobar"]).twice do
          result(is_element_present_results.shift)
        end
        mock(driver).do_command("click", ["id=foobar"]) {result}

        driver.click "id=foobar"
      end

      it "fails when element is not present" do
        is_element_present_results = [false, false, false, false]
        mock(driver).do_command("isElementPresent", ["id=foobar"]).times(4) do
          result(is_element_present_results.shift)
        end
        dont_allow(driver).do_command("click", [])

        proc {
          driver.click "id=foobar"
        }.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#select" do
      it "types when element is present and types" do
        is_element_present_results = [false, true]
        mock(driver).do_command("isElementPresent", ["id=foobar"]).twice do
          result is_element_present_results.shift
        end
        mock(driver).do_command("select", ["id=foobar", "value=3"]) {result}

        driver.select "id=foobar", "value=3"
      end

      it "fails when element is not present" do
        mock(driver).do_command("isElementPresent", ["id=foobar"]).times(4) do
          result false
        end
        dont_allow(driver).do_command("select", ["id=foobar", "value=3"])

        proc {
          driver.select "id=foobar", "value=3"
        }.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#click" do
      it "click when element is present and types" do
        is_element_present_results = [false, true]
        mock(driver).do_command("isElementPresent", ["id=foobar"]).twice do
          result is_element_present_results.shift
        end
        mock(driver).do_command("click", ["id=foobar"]) {result}

        driver.click "id=foobar"
      end

      it "fails when element is not present" do
        is_element_present_results = [false, false, false, false]
        mock(driver).is_element_present("id=foobar").times(4) do
          is_element_present_results.shift
        end
        dont_allow(driver).do_command("click", ["id=foobar"])

        proc {
          driver.click "id=foobar"
        }.should raise_error(Test::Unit::AssertionFailedError)
      end
    end
  end
end
