require File.expand_path("#{File.dirname(__FILE__)}/spec_suite")

class MainSpecSuite < SpecSuite
  def files
    Dir["#{File.dirname(__FILE__)}/polonium/**/*_spec.rb"]
  end
end

if $0 == __FILE__
  MainSpecSuite.new.run
end