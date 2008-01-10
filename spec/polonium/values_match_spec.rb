require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe "ValuesMatch" do
    attr_reader :fixture

    before do
      @fixture = Object.new
      fixture.extend ValuesMatch
    end

    describe "#values_match?" do
      it "when passed two matching strings, returns true" do
        fixture.values_match?("foo", "foo").should be_true
      end

      it "when passed two unmatching strings, returns true" do
        fixture.values_match?("foo", "bar").should be_false
      end
      
      it "when passed string and matching regexp, returns true" do
        fixture.values_match?("foo", /o/).should be_true
      end

      it "when passed string and unmatching regexp, returns true" do
        fixture.values_match?("foo", /r/).should be_false
      end
    end
  end
end
