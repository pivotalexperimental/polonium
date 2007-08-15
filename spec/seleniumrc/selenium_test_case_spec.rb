require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumTestCase, :shared => true do
  include SeleniumTestCaseSpec

  before(:each) do
    @test_case = SeleniumTestCaseSpec::MySeleniumTestCase.new
    stub_wait_for(@test_case)
    stub.probe(SeleniumElement).new do |element|
      stub_wait_for element
      element
    end
  end

  def sample_locator
    "sample_locator"
  end

  def sample_text
    "test text"
  end

  def create_sample_configuration
    configuration = Seleniumrc::SeleniumConfiguration.instance
    configuration.external_app_server_host = "test.com"
    configuration.external_app_server_port = 80
    configuration
  end
end

describe SeleniumTestCase, "instance methods" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "setup should not allow transactional fixtures" do
    stub(@test_case.class).use_transactional_fixtures.returns true

    expected_message = "Cannot use transactional fixtures if ActiveRecord concurrency is turned on (which is required for Selenium tests to work)."
    proc {@test_case.setup}.should raise_error(RuntimeError, expected_message)
  end

  it "default_timeout should be 20 seconds" do
    @test_case.default_timeout.should == 20000
  end

  it "wait_for should pass when the block returns true within time limit" do
    @test_case.wait_for(:timeout => 2) do
      true
    end
  end

  it "wait_for should raise a AssertionFailedError when block times out" do
    proc do
      @test_case.wait_for(:timeout => 2) {false}
    end.should raise_error(Test::Unit::AssertionFailedError, "Timeout exceeded (after 2 sec).")
  end

  it "wait_for_element_to_contain should pass when finding text within time limit" do
    is_element_present_results = [false, true]

    stub(base_selenium).is_element_present {is_element_present_results.shift}
    stub(base_selenium).get_eval("this.page().findElement(\"#{sample_locator}\").innerHTML") do
      sample_text
    end

    @test_case.wait_for_element_to_contain(sample_locator, sample_text)
  end

  it "wait_for_element_to_contain should fail when element not found in time" do
    is_element_present_results = [false, false, false, false]

    stub(base_selenium).is_element_present {is_element_present_results.shift}

    proc do
      @test_case.wait_for_element_to_contain(sample_locator, "")
    end.should raise_error(Test::Unit::AssertionFailedError, "Timeout exceeded (after 5 sec).")
  end

  it "wait_for_element_to_contain should fail when text does not match in time" do
    is_element_present_results = [false, true, true, true]

    stub(base_selenium).is_element_present {is_element_present_results.shift}
    stub(base_selenium).get_eval.
      with("this.page().findElement(\"#{sample_locator}\").innerHTML").
      returns(sample_text)

    proc do
      @test_case.wait_for_element_to_contain(sample_locator, "wrong text", nil, 1)
    end.should raise_error(Test::Unit::AssertionFailedError, "Timeout exceeded (after 1 sec).")
  end

  it "element_does_not_contain_text returns true when element is not on the page" do
    locator = "id=element_id"
    expected_text = "foobar"
    mock(base_selenium).is_element_present.with(locator).returns(false)

    @test_case.element_does_not_contain_text(locator, expected_text).should == true
  end

  it "element_does_not_contain_text returns true when element is on page and inner_html does not contain text" do
    locator = "id=element_id"
    inner_html = "Some text that does not contain the expected_text"
    expected_text = "foobar"
    mock(base_selenium).is_element_present.with(locator).returns(true)
    mock(@test_case).get_inner_html.with(locator).returns(inner_html)

    @test_case.element_does_not_contain_text(locator, expected_text).should == true
  end

  it "element_does_not_contain_text returns false when element is on page and inner_html does contain text" do
    locator = "id=element_id"
    inner_html = "foobar foobar foobar"
    expected_text = "foobar"
    mock(base_selenium).is_element_present.with(locator).returns(true)
    mock(@test_case).get_inner_html.with(locator).returns(inner_html)

    @test_case.element_does_not_contain_text(locator, expected_text).should == false
  end

  it "assert_element_does_not_contain should fail when text is present in element past timeout" do
    expected_text = "foobar"
    element_does_not_contain_text_results = [false, false, false, false]

    mock(@test_case).element_does_not_contain_text.
      with(sample_locator, expected_text).
      any_number_of_times.
      returns {element_does_not_contain_text_results.shift}

    proc do
      @test_case.assert_element_does_not_contain_text(sample_locator, expected_text, "Failure Message", 1)
    end.should raise_error(Test::Unit::AssertionFailedError, "Failure Message (after 1 sec).")
  end

  it "assert_text should assert the element is present and its text is equal to that passed in" do
    expected_text = "text"

    stub(base_selenium).is_element_present {|locator| locator == sample_locator}
    stub(base_selenium).get_text {expected_text}

    @test_case.assert_text(sample_locator, expected_text)
    proc {@test_case.assert_text('locator_fails', 'hello')}.
      should raise_error(Test::Unit::AssertionFailedError)
    proc {@test_case.assert_text(sample_locator, 'goodbye')}.
      should raise_error(Test::Unit::AssertionFailedError)
  end

  it "assert_value should assert the element is present and its value is equal to that passed in" do
    expected_value = "value"

    stub(base_selenium).is_element_present {|locator| locator == sample_locator}
    stub(base_selenium).get_value {expected_value}

    @test_case.assert_value(sample_locator, expected_value)
    proc {@test_case.assert_value('locator_fails', 'hello')}.
      should raise_error(Test::Unit::AssertionFailedError)
    proc {@test_case.assert_value(sample_locator, 'goodbye')}.
      should raise_error(Test::Unit::AssertionFailedError)
  end

   it "assert_selected should assert the element is present and its selected label is equal to that passed in" do
    expected_selected = "selected"

    stub(base_selenium).is_element_present {|locator| locator == sample_locator}
    stub(base_selenium).get_selected_label {expected_selected}

    @test_case.assert_selected(sample_locator, expected_selected)
    proc {@test_case.assert_selected('locator_fails', 'hello')}.
      should raise_error(Test::Unit::AssertionFailedError)
    proc {@test_case.assert_selected(sample_locator, 'goodbye')}.
      should raise_error(Test::Unit::AssertionFailedError)
  end

  it "assert_attribute should assert if the element is present AND if the element attribute is equal to that passed in" do
    expected_attribute = "attribute"

    stub(base_selenium).is_element_present.returns {|locator| locator == sample_locator}
    stub(base_selenium).get_attribute.returns(expected_attribute)

    @test_case.assert_attribute(sample_locator, expected_attribute)
    proc {@test_case.assert_attribute('locator_fails', 'hello')}.
      should raise_error(Test::Unit::AssertionFailedError)
    proc {@test_case.assert_attribute(sample_locator, 'goodbye')}.
      should raise_error(Test::Unit::AssertionFailedError)
  end

  it "assert_location_ends_in should assert that the url location ends with the passed in value" do
    mock(base_selenium).get_location.any_number_of_times.
      returns("http://home/location/1?thing=pa+ra+me+ter")

    expected_url = '/home/location/1?thing=pa+ra+me+ter'
    @test_case.assert_location_ends_in expected_url
    @test_case.assert_location_ends_in( 'location/1?thing=pa+ra+me+ter')
    @test_case.assert_location_ends_in( '1?thing=pa+ra+me+ter')
    proc {@test_case.assert_location_ends_in('the wrong thing')}.
      should raise_error(Test::Unit::AssertionFailedError)
    proc {@test_case.assert_location_ends_in('home/location')}.
      should raise_error(Test::Unit::AssertionFailedError)
  end

  it "assert_location_ends_in should not care about the order of the parameters" do
    mock(base_selenium).get_location.any_number_of_times.
      returns("http://home/location/1?thing=parameter&foo=bar")

    @test_case.assert_location_ends_in '/home/location/1?thing=parameter&foo=bar'
    @test_case.assert_location_ends_in '/home/location/1?foo=bar&thing=parameter'
  end

  it "is_text_in_order should check if text is in order" do
    locator = "id=foo"
    mock(base_selenium).get_text.with(locator).any_number_of_times.returns("one\ntwo\nthree\n")

    @test_case.is_text_in_order locator, "one", "two", "three"
  end

  it "should open home page" do
    configuration = create_sample_configuration

    @test_case.base_selenium = base_selenium

    mock(base_selenium).open("http://test.com:80")
    mock(base_selenium).wait_for_page_to_load(@test_case.default_timeout)
    stub(base_selenium).send {""}

    @test_case.open_home_page
  end
end

describe SeleniumTestCase, "#assert_visible" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "fails when element is not visible" do
    stub(base_selenium).is_visible.returns {false}

    proc {
      @test_case.assert_visible("id=element")
    }.should raise_error(Test::Unit::AssertionFailedError)
  end

  it "passes when element is not visible" do
    ticks = [false, false, false, true]
    stub(base_selenium).is_visible.returns {ticks.shift}

    @test_case.assert_visible("id=element")
  end
end

describe SeleniumTestCase, "#assert_not_visible" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "fails when element is visible" do
    stub(base_selenium).is_visible.returns {true}

    proc {
      @test_case.assert_not_visible("id=element")
    }.should raise_error(Test::Unit::AssertionFailedError)
  end

  it "passes when element is visible" do
    ticks = [true, true, true, false]
    stub(base_selenium).is_visible.returns {ticks.shift}

    @test_case.assert_not_visible("id=element")
  end
end

describe SeleniumTestCase, "#type" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "types when element is present and types" do
    is_element_present_results = [false, true]
    mock(base_selenium).is_element_present.with("id=foobar").twice.returns {is_element_present_results.shift}
    mock(base_selenium).type.with("id=foobar", "The Text")

    @test_case.type "id=foobar", "The Text"
  end

  it "fails when element is not present" do
    is_element_present_results = [false, false, false, false]
    mock(base_selenium).is_element_present.with("id=foobar").times(4).
      returns {is_element_present_results.shift}
    dont_allow(base_selenium).type

    proc {
      @test_case.type "id=foobar", "The Text"
    }.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#click" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "click when element is present and types" do
    is_element_present_results = [false, true]
    mock(base_selenium).is_element_present.with("id=foobar").twice.returns {is_element_present_results.shift}
    mock(base_selenium).click.with("id=foobar")

    @test_case.click "id=foobar"
  end

  it "fails when element is not present" do
    is_element_present_results = [false, false, false, false]
    mock(base_selenium).is_element_present.with("id=foobar").times(4).
      returns {is_element_present_results.shift}
    dont_allow(base_selenium).click

    proc {
      @test_case.click "id=foobar"
    }.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#select" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "types when element is present and types" do
    is_element_present_results = [false, true]
    mock(base_selenium).is_element_present.with("id=foobar").twice.returns {is_element_present_results.shift}
    mock(base_selenium).select.with("id=foobar", "value=3")

    @test_case.select "id=foobar", "value=3"
  end

  it "fails when element is not present" do
    is_element_present_results = [false, false, false, false]
    mock(base_selenium).is_element_present.with("id=foobar").times(4).
      returns {is_element_present_results.shift}
    dont_allow(base_selenium).select

    proc {
      @test_case.select "id=foobar", "value=3"
    }.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#wait_for_and_click" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "click when element is present and types" do
    is_element_present_results = [false, true]
    mock(base_selenium).is_element_present.with("id=foobar").twice.returns {is_element_present_results.shift}
    mock(base_selenium).click.with("id=foobar")

    @test_case.wait_for_and_click "id=foobar"
  end

  it "fails when element is not present" do
    is_element_present_results = [false, false, false, false]
    mock(base_selenium).is_element_present.with("id=foobar").times(4).
      returns {is_element_present_results.shift}
    dont_allow(base_selenium).click

    proc {
      @test_case.wait_for_and_click "id=foobar"
    }.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe "SeleniumTestCase in test browser mode and test fails" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "should stop interpreter when configuration says to stop test" do
    @test_case.configuration = "Seleniumrc::SeleniumConfiguration"
    mock(@test_case.configuration).test_browser_mode?.returns(true)

    stub(@test_case).passed?.returns(false)
    mock(@test_case.configuration).stop_selenese_interpreter?.with(false).returns(true)

    mock(base_selenium).stop.once
    @test_case.base_selenium = base_selenium

    @test_case.teardown
  end

  it "should not stop interpreter when configuration says not to stop test" do
    @test_case.configuration = "Seleniumrc::SeleniumConfiguration"
    mock(@test_case.configuration).test_browser_mode?.returns(true)

    stub(@test_case).passed?.returns(false)
    mock(@test_case.configuration).stop_selenese_interpreter?.with(false).returns(false)

    @test_case.base_selenium = base_selenium

    @test_case.teardown
  end
end

describe "SeleniumTestCase in test browser mode and test pass" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "should stop interpreter when configuration says to stop test" do
    @test_case.configuration = "Seleniumrc::SeleniumConfiguration"
    mock(@test_case.configuration).test_browser_mode?.returns(true)

    stub(@test_case).passed?.returns(true)
    mock(@test_case.configuration).stop_selenese_interpreter?.with(true).returns(true)

    mock(base_selenium).stop.once
    @test_case.base_selenium = base_selenium

    @test_case.teardown
  end

  it "should not stop interpreter when configuration says not to stop test" do
    @test_case.configuration = "Seleniumrc::SeleniumConfiguration"
    mock(@test_case.configuration).test_browser_mode?.returns(true)

    stub(@test_case).passed?.returns(true)
    mock(@test_case.configuration).stop_selenese_interpreter?.with(true).returns(false)

    @test_case.base_selenium = base_selenium

    @test_case.teardown
  end
end

describe "SeleniumTestCase not in suite browser mode" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "should not stop interpreter when tests fail" do
    @test_case.configuration = "Seleniumrc::SeleniumConfiguration"
    mock(@test_case.configuration).test_browser_mode?.returns(false)

    def @test_case.passed?; false; end

    @test_case.base_selenium = base_selenium

    @test_case.teardown
  end

   it "should stop interpreter when tests pass" do
     @test_case.configuration = "Seleniumrc::SeleniumConfiguration"
     mock(@test_case.configuration).test_browser_mode?.returns(false)

     stub(@test_case).passed?.returns(true)

     @test_case.base_selenium = base_selenium

     @test_case.teardown
   end
end

describe "SeleniumTestCase in test browser mode and test pass" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "should stop interpreter when configuration says to stop test" do
    @test_case.configuration = "Seleniumrc::SeleniumConfiguration"
    mock(@test_case.configuration).test_browser_mode?.returns(true)

    stub(@test_case).passed?.returns(true)
    mock(@test_case.configuration).stop_selenese_interpreter?.with(true).returns(true)

    mock(base_selenium).stop.once
    @test_case.base_selenium = base_selenium

    @test_case.teardown
  end

  it "should not stop interpreter when configuration says not to stop test" do
    @test_case.configuration = "Seleniumrc::SeleniumConfiguration"
    mock(@test_case.configuration).test_browser_mode?.returns(true)

    stub(@test_case).passed?.returns(true)
    mock(@test_case.configuration).stop_selenese_interpreter?.with(true).returns(false)

    @test_case.base_selenium = base_selenium

    @test_case.teardown
  end
end
end
