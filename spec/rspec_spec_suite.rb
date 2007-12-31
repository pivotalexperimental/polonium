require File.expand_path("#{File.dirname(__FILE__)}/spec_suite")

class RspecSpecSuite < SpecSuite
  def files
    Dir["#{File.dirname(__FILE__)}/rspec/**/*_spec.rb"]
  end
end

if $0 == __FILE__
  RspecSpecSuite.new.run
end