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

describe SeleniumElement, "#is_not_present" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  it "passes when element is not present" do
    ticks = [true, true, true, false]
    mock(@selenium).is_element_present(@element_locator) do
      ticks.shift
    end.times(4)
    @element.is_not_present
  end

  it "fails when element is present" do
    stub(@selenium).is_element_present(@element_locator) {true}
    proc do
      @element.is_not_present
    end.should raise_error("Expected element 'id=foobar' to be absent, but it was not (after 5 sec)")
  end
end

describe SeleniumElement, "#has_value" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  it "passes when element is present and value is expected value" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    value_ticks = [nil, nil, nil, "joe"]
    mock(@selenium).get_value(@element_locator) do
      value_ticks.shift
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
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    label_ticks = ["jane", "jane", "jane", "joe"]
    mock(@selenium).get_attribute(@element_locator) do
      label_ticks.shift
    end.times(4)
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
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    label_ticks = ["jane", "jane", "jane", "joe"]
    mock(@selenium).get_selected_label(@element_locator) do
      label_ticks.shift
    end.times(4)
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

describe SeleniumElement, "#is_visible" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
  end

  it "passes when element exists and is visible" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    visible_ticks = [false, false, false, true]
    mock(@selenium).is_visible(@element_locator) do
      visible_ticks.shift
    end.times(4)
    @element.is_visible
  end

  it "fails when element is present and value is not expected" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).is_visible(@element_locator) {false}
    proc do
      @element.is_visible
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.is_visible
    end.should raise_error
  end
end

describe SeleniumElement, "#is_checked" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
  end

  it "passes when element is present and value is expected value" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    checked_ticks = [false, false, false, true]
    mock(@selenium).is_checked(@element_locator) do
      checked_ticks.shift
    end.times(4)
    @element.is_checked
  end

  it "fails when element is present and value is not expected" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).is_checked(@element_locator) {false}
    proc do
      @element.is_checked
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.is_checked
    end.should raise_error
  end
end

describe SeleniumElement, "#is_not_checked" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
  end

  it "passes when element is present and value is expected value" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    checked_ticks = [true, true, true, false]
    mock(@selenium).is_checked(@element_locator) do
      checked_ticks.shift
    end.times(4)
    @element.is_not_checked
  end

  it "fails when element is present and value is not expected" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).is_checked(@element_locator) {true}
    proc do
      @element.is_not_checked
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.is_not_checked
    end.should raise_error
  end
end

describe SeleniumElement, "#has_text" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
  end

  it "passes when element is present and value is expected value" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    checked_ticks = ["no match", "no match", "no match", "match"]
    mock(@selenium).get_text(@element_locator) do
      checked_ticks.shift
    end.times(4)
    @element.has_text("match")
  end

  it "fails when element is present and value is not expected" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).get_text(@element_locator) {"no match"}
    proc do
      @element.has_text "match"
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.has_text "match"
    end.should raise_error
  end
end

describe SeleniumElement, "#contains_text" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
    @evaled_js = "this.page().findElement(\"#{@element_locator}\").innerHTML"
  end

  it "passes when element is present and the element contains text" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    inner_html_ticks = ["html", "html", "html", "html match html"]
    mock(@selenium).get_eval(@evaled_js) do
      inner_html_ticks.shift
    end.times(4)
    @element.contains_text("match")
  end

  it "fails when element is present and the element does not contain text" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).get_eval(@evaled_js) {"html"}
    proc do
      @element.contains_text "match"
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.contains_text "match"
    end.should raise_error
  end
end

describe SeleniumElement, "#does_not_contain_text" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
    @evaled_js = "this.page().findElement(\"#{@element_locator}\").innerHTML"
  end

  it "passes when element is present and the element does not contain text" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    inner_html_ticks = ["html match html", "html match html", "html match html", "html"]
    mock(@selenium).get_eval(@evaled_js) do
      inner_html_ticks.shift
    end.times(4)
    @element.does_not_contain_text("match")
  end

  it "fails when element is present and the element contains text" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).get_eval(@evaled_js) {"html match html"}
    proc do
      @element.does_not_contain_text "match"
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.does_not_contain_text "match"
    end.should raise_error
  end
end

describe SeleniumElement, "#has_next_sibling" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
    @evaled_js = "this.page().findElement('#{@element_locator}').nextSibling.id"
  end

  it "passes when element is present and value is expected value" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    inner_html_ticks = ["", "", "", "next_element"]
    mock(@selenium).get_eval(@evaled_js) do
      inner_html_ticks.shift
    end.times(4)
    @element.has_next_sibling("next_element")
  end

  it "fails when element is present and value is not expected" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).get_eval(@evaled_js) {""}
    proc do
      @element.has_next_sibling "next_element"
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.has_next_sibling "match"
    end.should raise_error
  end
end

describe SeleniumElement, "#has_text_in_order" do
  it_should_behave_like "Seleniumrc::SeleniumElement"

  prepend_before do
    @element_locator = "id=foobar"
    @evaled_js = "this.page().findElement('#{@element_locator}').nextSibling.id"
  end

  it "passes when element is present and value is expected value" do
    element_ticks = [false, false, false, true]
    mock(@selenium).is_element_present(@element_locator) do
      element_ticks.shift
    end.times(4)
    get_text_ticks = [
      "no match",
      "no match",
      "no match",
      "one\ntwo\nthree",
    ]
    mock(@selenium).get_text(@element_locator) do
      get_text_ticks.shift
    end.times(4)
    @element.has_text_in_order('one', 'two', 'three')
  end

  it "fails when element is present and value is not expected" do
    stub(@selenium).is_element_present(@element_locator) {true}
    stub(@selenium).get_text(@element_locator) {"no match"}
    proc do
      @element.has_text_in_order 'one', 'two', 'three'
    end.should raise_error
  end

  it "fails when element is not present" do
    stub(@selenium).is_element_present(@element_locator) {false}
    proc do
      @element.has_text_in_order 'one', 'two', 'three'
    end.should raise_error
  end
end
end
