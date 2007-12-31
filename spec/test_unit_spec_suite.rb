require File.expand_path("#{File.dirname(__FILE__)}/spec_suite")

class TestUnitSpecSuite < SpecSuite
  def files
    Dir["#{File.dirname(__FILE__)}/test_unit/**/*_spec.rb"]
  end
end

if $0 == __FILE__
  TestUnitSpecSuite.new.run
end