require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Polonium
  describe TestCase, "Class methods" do
    include TestCaseSpecHelper
    it "should not use transactional fixtures by default" do
      Polonium::TestCase.use_transactional_fixtures.should ==  false
    end

    it "should use instantiated fixtures by default" do
      Polonium::TestCase.use_instantiated_fixtures.should ==  true
    end
  end
end
