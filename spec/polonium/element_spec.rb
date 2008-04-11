require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe Element do
    it_should_behave_like "Selenium"
    include TestCaseSpecHelper
    attr_reader :driver, :element, :element_locator

    before do
      @driver = ::Polonium::Driver.new('http://test.host', 4000, "*firefox", 'http://test.host')
      @element_locator ||= "id=foobar"
      @element = Element.new(driver, element_locator)
    end

    describe "#initialize" do
      it "sets the locator" do
        element.locator.should == element_locator
      end

      it "sets the selenium object" do
        element.driver.should == driver
      end
    end

    describe "#assert_element_present" do
      it "passes when element is present" do
        ticks = [false, false, false, true]
        mock(driver).do_command("isElementPresent", [element_locator]).times(4) do
          result ticks.shift
        end
        element.assert_element_present
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_element_present
        end.should raise_error("Expected element 'id=foobar' to be present, but it was not (after 5 sec)")
      end
    end

    describe "#is_present?" do
      it "returns true when element is present" do
        mock(driver).is_element_present(element_locator) {true}
        element.is_present?.should be_true
      end

      it "returns false when element is not present" do
        mock(driver).is_element_present(element_locator) {false}
        element.is_present?.should be_false
      end
    end

    describe "#contains?" do
      describe "when passed a String" do
        it "returns true when inner html does contain passed in text" do
          mock(driver).get_inner_html(element_locator) {"hello world"}
          element.contains?("hello").should be_true
        end

        it "returns false when inner html does not contain passed in text" do
          mock(driver).get_inner_html(element_locator) {"hello world"}
          element.contains?("goodbye").should be_false
        end
      end

      describe "when passed a Regexp" do
        it "returns true when inner html does match passed in Regexp" do
          mock(driver).get_inner_html(element_locator) {"hello world"}
          element.contains?(/hello/).should be_true
        end

        it "returns false when inner html does not match passed in Regexp" do
          mock(driver).get_inner_html(element_locator) {"hello world"}
          element.contains?(/goodbye/).should be_false
        end
      end
      
    end

    describe "#assert_element_not_present" do
      it "passes when element is not present" do
        ticks = [true, true, true, false]
        mock(driver).is_element_present(element_locator) do
          ticks.shift
        end.times(4)
        element.assert_element_not_present
      end

      it "fails when element is present" do
        stub(driver).is_element_present(element_locator) {true}
        proc do
          element.assert_element_not_present
        end.should raise_error("Expected element 'id=foobar' to be absent, but it was not (after 5 sec)")
      end
    end

    describe "#is_not_present?" do
      it "returns true when element is not present" do
        mock(driver).is_element_present(element_locator) {false}
        element.is_not_present?.should be_true
      end

      it "returns false when element is present" do
        mock(driver).is_element_present(element_locator) {true}
        element.is_not_present?.should be_false
      end
    end

    describe "#assert_value" do
      it "passes when element is present and value is expected value" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) do
          element_ticks.shift
        end.times(4)
        value_ticks = [nil, nil, nil, "joe"]
        mock(driver).get_value(element_locator) do
          value_ticks.shift
        end.times(4)
        element.assert_value("joe")
      end

      it "fails when element is present and not expected value" do
        mock(driver).is_element_present(element_locator) {true}
        stub(driver).get_value(element_locator) {"jane"}
        proc do
          element.assert_value("joe")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_value("joe")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#has_value?" do
      it "returns true when value is expected value" do
        mock(driver).get_value(element_locator) {"joe"}
        element.has_value?("joe").should be_true
      end

      it "returns false when value is not expected value" do
        stub(driver).get_value(element_locator) {"jane"}
        element.has_value?("joe").should be_false
      end
    end

    describe "#assert_attribute" do
      it "passes when element is present and value is expected value" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) do
          element_ticks.shift
        end.times(4)
        label_ticks = ["jane", "jane", "jane", "joe"]
        mock(driver).get_attribute("#{element_locator}@theattribute") do
          label_ticks.shift
        end.times(4)
        mock.proxy(element).values_match?.with_any_args.times(4)
        
        element.assert_attribute('theattribute', "joe")
      end

      it "fails when element is present and value is not expected" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).get_attribute("#{element_locator}@theattribute") {"jane"}
        mock.proxy(element).values_match?.with_any_args.times(4)
        proc do
          element.assert_attribute('theattribute', "joe")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_attribute('theattribute', "joe")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_attribute_does_not_contain" do
      it "passes when element is present and value does not contain the illegal value" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).get_attribute("#{element_locator}@theattribute") { "jane" }
        element.assert_attribute_does_not_contain('theattribute', "joe")
      end

      it "passes when element is present and value does contain the illegal value" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).get_attribute("#{element_locator}@theattribute") { "jane" }
        proc do
          element.assert_attribute_does_not_contain('theattribute', "jane")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
      
      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_attribute_does_not_contain('theattribute', "jane")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_selected" do
      before do
        @element_locator = "id=foobar"
      end

      it "passes when element is present and value is expected value" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) do
          element_ticks.shift
        end.times(4)
        label_ticks = ["jane", "jane", "jane", "joe"]
        mock(driver).get_selected_label(element_locator) do
          label_ticks.shift
        end.times(4)
        mock.proxy(element).values_match?.with_any_args.times(4)

        element.assert_selected("joe")
      end

      it "fails when element is present and value is not expected" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).get_selected_label(element_locator) {"jane"}
        mock.proxy(element).values_match?.with_any_args.times(4)
        
        proc do
          element.assert_selected("joe")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_selected("joe")
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_visible" do
      before do
        @element_locator = "id=foobar"
      end

      it "passes when element exists and is visible" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) do
          element_ticks.shift
        end.times(4)
        visible_ticks = [false, false, false, true]
        mock(driver).is_visible(element_locator) do
          visible_ticks.shift
        end.times(4)
        element.assert_visible
      end

      it "fails when element is present and is not visible" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).is_visible(element_locator) {false}
        proc do
          element.assert_visible
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_visible
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_not_visible" do
      before do
        @element_locator = "id=foobar"
      end

      it "passes when element exists and is not visible" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) do
          element_ticks.shift
        end.times(4)
        visible_ticks = [true, true, true, false]
        mock(driver).is_visible(element_locator) do
          visible_ticks.shift
        end.times(4)
        element.assert_not_visible
      end

      it "fails when element is present and is visible" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).is_visible(element_locator) {true}
        proc do
          element.assert_not_visible
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_visible
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_checked" do
      before do
        @element_locator = "id=foobar"
      end

      it "passes when element is present and value is expected value" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) do
          element_ticks.shift
        end.times(4)
        checked_ticks = [false, false, false, true]
        mock(driver).is_checked(element_locator) do
          checked_ticks.shift
        end.times(4)
        element.assert_checked
      end

      it "fails when element is present and value is not expected" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).is_checked(element_locator) {false}
        proc do
          element.assert_checked
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_checked
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_not_checked" do
      before do
        @element_locator = "id=foobar"
      end

      it "passes when element is present and value is expected value" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) do
          element_ticks.shift
        end.times(4)
        checked_ticks = [true, true, true, false]
        mock(driver).is_checked(element_locator) do
          checked_ticks.shift
        end.times(4)
        element.assert_not_checked
      end

      it "fails when element is present and value is not expected" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).is_checked(element_locator) {true}
        proc do
          element.assert_not_checked
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_not_checked
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_text" do
      before do
        @element_locator = "id=foobar"
      end

      it "passes when element is present and value is expected value" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) do
          element_ticks.shift
        end.times(4)
        checked_ticks = ["no match", "no match", "no match", "match"]
        mock(driver).get_text(element_locator) do
          checked_ticks.shift
        end.times(4)
        mock.proxy(element).values_match?.with_any_args.times(4)

        element.assert_text("match")
      end

      it "fails when element is present and value is not expected" do
        stub(driver).is_element_present(element_locator) {true}
        stub(driver).get_text(element_locator) {"no match"}
        mock.proxy(element).values_match?.with_any_args.times(4)
        
        proc do
          element.assert_text "match"
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_text "match"
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_contains" do
      before do
        @element_locator = "id=foobar"
        @evaled_js = "this.page().findElement(\"#{element_locator}\").innerHTML"
      end

      describe "when passed a String" do
        it "passes when element is present and the element contains text" do
          element_ticks = [false, false, false, true]
          mock(driver).is_element_present(element_locator) do
            element_ticks.shift
          end.times(4)
          inner_html_ticks = ["html", "html", "html", "html match html"]
          mock(driver).get_eval(@evaled_js) do
            inner_html_ticks.shift
          end.times(4)
          element.assert_contains("match")
        end

        it "fails when element is present and the element does not contain text" do
          stub(driver).is_element_present(element_locator) {true}
          stub(driver).get_eval(@evaled_js) {"html"}
          proc do
            element.assert_contains "this is not contained in the html"
          end.should raise_error(Test::Unit::AssertionFailedError)
        end
      end

      describe "when passed a Regexp" do
        it "passes when element is present and the element contains text that matches the regexp" do
          element_ticks = [false, false, false, true]
          mock(driver).is_element_present(element_locator) do
            element_ticks.shift
          end.times(4)
          inner_html_ticks = ["html", "html", "html", "html match html"]
          mock(driver).get_eval(@evaled_js) do
            inner_html_ticks.shift
          end.times(4)
          element.assert_contains(/match/)
        end

        it "fails when element is present and the element does not contain text that matches the regexp" do
          stub(driver).is_element_present(element_locator) {true}
          stub(driver).get_eval(@evaled_js) {"html"}
          proc do
            element.assert_contains /blahblah/
          end.should raise_error(Test::Unit::AssertionFailedError)
        end
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_contains "the element does not exist"
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "calls assert_contains_in_order when passed an array" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(element_locator) {true}
        mock(driver).get_text(element_locator) {"foo bar baz"}

        mock.proxy(element).assert_contains_in_order("foo", "bar", "baz")
        element.assert_contains(["foo", "bar", "baz"])
      end
    end

    describe "#assert_does_not_contain" do
      before do
        @element_locator = "id=foobar"
        @evaled_js = "this.page().findElement(\"#{element_locator}\").innerHTML"
      end

      describe "when passed a String" do
        it "passes when element is present and the element does not contain text" do
          element_ticks = [false, false, false, true]
          mock(driver).is_element_present(element_locator) do
            element_ticks.shift
          end.times(4)
          inner_html_ticks = ["html match html", "html match html", "html match html", "html"]
          mock(driver).get_eval(@evaled_js) do
            inner_html_ticks.shift
          end.times(4)
          element.assert_does_not_contain("match")
        end

        it "fails when element is present and the element contains text" do
          stub(driver).is_element_present(element_locator) {true}
          stub(driver).get_eval(@evaled_js) {"html match html"}
          proc do
            element.assert_does_not_contain "match"
          end.should raise_error(Test::Unit::AssertionFailedError)
        end
      end

      describe "when passed a Regexp" do
        it "passes when element is present and the element does not contain text that matches the Regexp" do
          element_ticks = [false, false, false, true]
          mock(driver).is_element_present(element_locator) do
            element_ticks.shift
          end.times(4)
          inner_html_ticks = ["html match html", "html match html", "html match html", "html"]
          mock(driver).get_eval(@evaled_js) do
            inner_html_ticks.shift
          end.times(4)
          element.assert_does_not_contain(/match/)
        end

        it "fails when element is present and the element contains text" do
          stub(driver).is_element_present(element_locator) {true}
          stub(driver).get_eval(@evaled_js) {"html match html"}
          proc do
            element.assert_does_not_contain /match/
          end.should raise_error(Test::Unit::AssertionFailedError)
        end
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(element_locator) {false}
        proc do
          element.assert_does_not_contain "match"
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_next_sibling" do
      before do
        @element_locator = "id=foobar"
        @evaled_js = "this.page().findElement('#{@element_locator}').nextSibling.id"
      end

      it "passes when element is present and value is expected value" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(@element_locator) do
          element_ticks.shift
        end.times(4)
        inner_html_ticks = ["", "", "", "next_element"]
        mock(driver).get_eval(@evaled_js) do
          inner_html_ticks.shift
        end.times(4)
        element.assert_next_sibling("next_element")
      end

      it "fails when element is present and value is not expected" do
        stub(driver).is_element_present(@element_locator) {true}
        stub(driver).get_eval(@evaled_js) {""}
        proc do
          element.assert_next_sibling "next_element"
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(@element_locator) {false}
        proc do
          element.assert_next_sibling "match"
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#assert_contains_in_order" do
      before do
        @element_locator = "id=foobar"
        @evaled_js = "this.page().findElement('#{@element_locator}').nextSibling.id"
      end

      it "passes when element is present and passed in text and Regexp matches are in order" do
        element_ticks = [false, false, false, true]
        mock(driver).is_element_present(@element_locator) do
          element_ticks.shift
        end.times(4)
        get_text_ticks = [
          "no match",
          "no match",
          "no match",
          "one\ntwo\nthree",
        ]
        mock(driver).get_text(@element_locator) do
          get_text_ticks.shift
        end.times(4)
        element.assert_contains_in_order('one', /two/, 'three')
      end

      it "fails when element is present and value is not expected" do
        stub(driver).is_element_present(@element_locator) {true}
        stub(driver).get_text(@element_locator) {"no match"}
        proc do
          element.assert_contains_in_order 'one', 'two', 'three'
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(@element_locator) {false}
        proc do
          element.assert_contains_in_order 'one', 'two', 'three'
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end
    
    describe "#assert_number_of_children" do
      before do
        @element_locator = "id=foobar"
        @evaled_js = "this.page().findElement('#{@element_locator}').childNodes.length"
      end
      
      it "passes when element is present and it contains the correct number of (direct) children" do
        stub(driver).is_element_present(@element_locator) {true}
        stub(driver).get_eval(@evaled_js) { 3 }
        element.assert_number_of_children(3)
      end

      it "fails when element is present and it contains the wrong number of (direct) children" do
        stub(driver).is_element_present(@element_locator) {true}
        stub(driver).get_eval(@evaled_js) { 999 }
        proc do
          element.assert_number_of_children(3)
        end.should raise_error(Test::Unit::AssertionFailedError)
      end

      it "fails when element is not present" do
        stub(driver).is_element_present(@element_locator) {false}
        proc do
          element.assert_number_of_children 3
        end.should raise_error(Test::Unit::AssertionFailedError)
      end
    end

    describe "#method_missing" do
      it "delegates command to the driver" do
        element.methods.should_not include('foobar')
        mock(driver).foobar(@element_locator)
        element.foobar
      end
    end
  end
end
