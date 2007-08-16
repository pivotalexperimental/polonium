require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe SeleniumTestCase, :shared => true do
  include SeleniumTestCaseSpec

  before(:each) do
    @test_case = SeleniumTestCaseSpec::MySeleniumTestCase.new
    @base_selenium = "Base Selenium"
    @test_case.base_selenium = @base_selenium
    @configuration = create_sample_configuration
    
    stub_wait_for(@test_case)
    stub.probe(SeleniumElement).new do |element|
      stub_wait_for element
      element
    end
    stub.probe(SeleniumPage).new do |page|
      stub_wait_for page
      page
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

describe SeleniumTestCase, "#setup" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "should not allow transactional fixtures" do
    stub(@test_case.class).use_transactional_fixtures.returns true

    expected_message = "Cannot use transactional fixtures if ActiveRecord concurrency is turned on (which is required for Selenium tests to work)."
    proc {@test_case.setup}.should raise_error(RuntimeError, expected_message)
  end
end

describe SeleniumTestCase, "#wait_for" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "should pass when the block returns true within time limit" do
    @test_case.wait_for(:timeout => 2) do
      true
    end
  end

  it "should raise a AssertionFailedError when block times out" do
    proc do
      @test_case.wait_for(:timeout => 2) {false}
    end.should raise_error(Test::Unit::AssertionFailedError, "Timeout exceeded (after 2 sec)")
  end
end

describe SeleniumTestCase, "#wait_for_element_to_contain" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "should pass when finding text within time limit" do
    is_element_present_results = [false, true]

    stub(base_selenium).is_element_present {is_element_present_results.shift}
    stub(base_selenium).get_eval("this.page().findElement(\"#{sample_locator}\").innerHTML") do
      sample_text
    end

    @test_case.wait_for_element_to_contain(sample_locator, sample_text)
  end

  it "should fail when element not found in time" do
    is_element_present_results = [false, false, false, false]

    stub(base_selenium).is_element_present {is_element_present_results.shift}

    proc do
      @test_case.wait_for_element_to_contain(sample_locator, "")
    end.should raise_error(Test::Unit::AssertionFailedError, "Timeout exceeded (after 5 sec)")
  end

  it "should fail when text does not match in time" do
    is_element_present_results = [false, true, true, true]

    stub(base_selenium).is_element_present {is_element_present_results.shift}
    stub(base_selenium).get_eval.
      with("this.page().findElement(\"#{sample_locator}\").innerHTML").
      returns(sample_text)

    proc do
      @test_case.wait_for_element_to_contain(sample_locator, "wrong text", nil, 1)
    end.should raise_error(Test::Unit::AssertionFailedError, "Timeout exceeded (after 1 sec)")
  end
end

describe SeleniumTestCase, "#default_timeout" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "default_timeout should be 20 seconds" do
    @test_case.default_timeout.should == 20000
  end
end

describe SeleniumTestCase, "#open_home_page" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  it "opens home page" do
    mock(base_selenium).open("http://test.com:80")
    mock(base_selenium).wait_for_page_to_load(@test_case.default_timeout)
    stub(base_selenium).send {""}

    @test_case.open_home_page
  end
end

describe SeleniumTestCase, "#open_and_wait" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumPage).new(base_selenium) do |page|
      stub_wait_for page
      mock.proxy(page).open_and_wait("/users/list")
      page
    end
  end

  it "opens the url and waits for the page to load" do
    mock(base_selenium) do |o|
      o.open("/users/list")
      o.wait_for_page_to_load(@test_case.default_timeout)
      o.get_title {"Users in the project"}
    end
    @test_case.open_and_wait("/users/list")
  end
end

describe SeleniumTestCase, "#assert_title" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumPage).new(base_selenium) do |page|
      stub_wait_for page
      mock.proxy(page).has_title("my page", {})
      page
    end
  end

  it "passes when title is expected" do
    mock(base_selenium).get_title {"my page"}
    @test_case.assert_title("my page")
  end

  it "fails when title is not expected" do
    stub(base_selenium).get_title {"no page"}
    proc do
      @test_case.assert_title("my page")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_text_present" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumPage).new(base_selenium) do |page|
      stub_wait_for page
      mock.proxy(page).is_text_present("my page", {})
      page
    end
  end

  it "passes when text is in page" do
    ticks = [false, false, false, true]
    mock(base_selenium).is_text_present("my page") do
      ticks.shift
    end.times(4)
    @test_case.assert_text_present("my page")
  end

  it "fails when text is not in page" do
    stub(base_selenium).is_text_present("my page") {false}
    proc do
      @test_case.assert_text_present("my page")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_text_not_present" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumPage).new(base_selenium) do |page|
      stub_wait_for page
      mock.proxy(page).is_text_not_present("my page", {})
      page
    end
  end

  it "passes when text is not in page" do
    ticks = [true, true, true, false]
    mock(base_selenium).is_text_present("my page") do
      ticks.shift
    end.times(4)
    @test_case.assert_text_not_present("my page")
  end

  it "fails when text is in page" do
    stub(base_selenium).is_text_present("my page") {true}
    proc do
      @test_case.assert_text_not_present("my page")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_location_ends_in" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    @ends_with = "foobar.com?arg1=2"
    mock.proxy(SeleniumPage).new(base_selenium) do |page|
      stub_wait_for page
      mock.proxy(page).url_ends_with(@ends_with, {})
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
    mock(base_selenium).get_location do
      ticks.shift
    end.times(4)
    @test_case.assert_location_ends_in(@ends_with)
  end

  it "fails when the url does not end with the passed in value" do
    stub(base_selenium).get_location {"http://no.com"}
    proc do
      @test_case.assert_location_ends_in(@ends_with)
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_element_present" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).is_present({})
      element
    end
  end

  it "passes when element is present" do
    ticks = [false, false, false, true]
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) do
        ticks.shift
      end.times(4)
    end
    @test_case.assert_element_present(sample_locator)
  end

  it "fails when element is not present" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {false}
    end
    proc do
      @test_case.assert_element_present(sample_locator)
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_element_not_present" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).is_not_present({})
      element
    end
  end

  it "passes when element is not present" do
    ticks = [true, true, true, false]
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) do
        ticks.shift
      end.times(4)
    end
    @test_case.assert_element_not_present(sample_locator)
  end

  it "fails when element is present" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
    end
    proc do
      @test_case.assert_element_not_present(sample_locator)
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_value" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).has_value("passed in value")
      element
    end
  end

  it "passes when value is expected" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_value(sample_locator) {"passed in value"}
    end
    @test_case.assert_value(sample_locator, "passed in value")
  end

  it "fails when value is not expected" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_value(sample_locator) {"another value"}
    end
    proc do
      @test_case.assert_value(sample_locator, "passed in value")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_element_contains" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).contains_text("passed in value", {})
      element
    end
    @evaled_js = "this.page().findElement(\"#{sample_locator}\").innerHTML"
  end

  it "passes when text is in the element's inner_html" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_eval(@evaled_js) do
        "html passed in value html"
      end
    end
    @test_case.assert_element_contains(sample_locator, "passed in value")
  end

  it "fails when text is not in the element's inner_html" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_eval(@evaled_js) {"another value"}
    end
    proc do
      @test_case.assert_element_contains(sample_locator, "passed in value")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#element_does_not_contain_text" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"
  
  it "returns true when element is not on the page" do
    locator = "id=element_id"
    expected_text = "foobar"
    mock(base_selenium).is_element_present.with(locator).returns(false)

    @test_case.element_does_not_contain_text(locator, expected_text).should == true
  end

  it "returns true when element is on page and inner_html does not contain text" do
    locator = "id=element_id"
    inner_html = "Some text that does not contain the expected_text"
    expected_text = "foobar"
    mock(base_selenium).is_element_present.with(locator).returns(true)
    mock(@test_case).get_inner_html.with(locator).returns(inner_html)

    @test_case.element_does_not_contain_text(locator, expected_text).should == true
  end

  it "returns false when element is on page and inner_html does contain text" do
    locator = "id=element_id"
    inner_html = "foobar foobar foobar"
    expected_text = "foobar"
    mock(base_selenium).is_element_present.with(locator).returns(true)
    mock(@test_case).get_inner_html.with(locator).returns(inner_html)

    @test_case.element_does_not_contain_text(locator, expected_text).should == false
  end
end

describe SeleniumTestCase, "#assert_element_does_not_contain_text" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).does_not_contain_text("passed in value", {})
      element
    end
    @evaled_js = "this.page().findElement(\"#{sample_locator}\").innerHTML"
  end

  it "passes when text is not in the element's inner_html" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_eval(@evaled_js) do
        "another value"
      end
    end
    @test_case.assert_element_does_not_contain_text(sample_locator, "passed in value")
  end

  it "fails when text is in the element's inner_html" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_eval(@evaled_js) {"html passed in value html"}
    end
    proc do
      @test_case.assert_element_does_not_contain_text(sample_locator, "passed in value")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_attribute" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).has_attribute("passed in value")
      element
    end
  end

  it "passes when attribute is expected" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_attribute(sample_locator) {"passed in value"}
    end
    @test_case.assert_attribute(sample_locator, "passed in value")
  end
  
  it "fails when attribute is not expected" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_attribute(sample_locator) {"another value"}
    end
    proc do
      @test_case.assert_attribute(sample_locator, "passed in value")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_selected" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).has_selected("passed_in_element")
      element
    end
  end

  it "passes when selected is expected" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_selected_label(sample_locator) {"passed_in_element"}
    end
    @test_case.assert_selected(sample_locator, "passed_in_element")
  end

  it "fails when selected is not expected" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_selected_label(sample_locator) {"another_element"}
    end
    proc do
      @test_case.assert_selected(sample_locator, "passed_in_element")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end  
end

describe SeleniumTestCase, "#assert_checked" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).is_checked
      element
    end
  end

  it "passes when checked" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.is_checked(sample_locator) {true}
    end
    @test_case.assert_checked(sample_locator)
  end

  it "fails when not checked" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.is_checked(sample_locator) {false}
    end
    proc do
      @test_case.assert_checked(sample_locator)
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_not_checked" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).is_not_checked
      element
    end
  end

  it "passes when not checked" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.is_checked(sample_locator) {false}
    end
    @test_case.assert_not_checked(sample_locator)
  end

  it "fails when checked" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.is_checked(sample_locator) {true}
    end
    proc do
      @test_case.assert_not_checked(sample_locator)
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_text" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).has_text("expected text", {})
      element
    end
  end

  it "passes when text is expected" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_text(sample_locator) {"expected text"}
    end
    @test_case.assert_text(sample_locator, "expected text")
  end

  it "fails when text is not expected" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_text(sample_locator) {"unexpected text"}
    end
    proc do
      @test_case.assert_text(sample_locator, "expected text")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_visible" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).is_visible({})
      element
    end
  end

  it "passes when element is visible" do
    mock(base_selenium).is_element_present(sample_locator) {true}
    mock(base_selenium).is_visible(sample_locator) {true}

    @test_case.assert_visible(sample_locator)
  end
  
  it "fails when element is not visible" do
    mock(base_selenium).is_element_present(sample_locator) {true}
    stub(base_selenium).is_visible.returns {false}

    proc {
      @test_case.assert_visible(sample_locator)
    }.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_not_visible" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).is_not_visible({})
      element
    end
  end

  it "passes when element is present and is not visible" do
    mock(base_selenium).is_element_present(sample_locator) {true}
    mock(base_selenium).is_visible(sample_locator) {false}

    @test_case.assert_not_visible(sample_locator)
  end
  
  it "fails when element is visible" do
    mock(base_selenium).is_element_present(sample_locator) {true}
    stub(base_selenium).is_visible(sample_locator) {true}

    proc {
      @test_case.assert_not_visible(sample_locator)
    }.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_next_sibling" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).has_next_sibling("next_sibling", {})
      element
    end
    @evaled_js = "this.page().findElement('#{sample_locator}').nextSibling.id"
  end

  it "passes when passed next sibling id" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_eval(@evaled_js) {"next_sibling"}
    end
    @test_case.assert_next_sibling(sample_locator, "next_sibling")
  end

  it "fails when not passed next sibling id" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_eval(@evaled_js) {"wrong_sibling"}
    end
    proc do
      @test_case.assert_next_sibling(sample_locator, "next_sibling")
    end.should raise_error(Test::Unit::AssertionFailedError)
  end
end

describe SeleniumTestCase, "#assert_text_in_order" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"

  before do
    mock.proxy(SeleniumElement).new(base_selenium, sample_locator) do |element|
      stub_wait_for element
      mock.proxy(element).has_text_in_order("one", "two", "three")
      element
    end
    @evaled_js = "this.page().findElement('#{sample_locator}').nextSibling.id"
  end

  it "passes when text is in order" do
    mock(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_text(sample_locator) {"one\ntwo\nthree\n"}
    end
    @test_case.assert_text_in_order sample_locator, "one", "two", "three"
  end

  it "fails when element is present and text is not in order" do
    stub(base_selenium) do |o|
      o.is_element_present(sample_locator) {true}
      o.get_text(sample_locator) {"<html>one\ntext not in order\n</html>"}
    end
    proc do
      @test_case.assert_text_in_order sample_locator, "one", "two", "three"
    end.should raise_error(Test::Unit::AssertionFailedError)
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

describe SeleniumTestCase, "#page" do
  it_should_behave_like "Seleniumrc::SeleniumTestCase"
  
  it "returns page" do
    @test_case.page.should == SeleniumPage.new(base_selenium)
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
