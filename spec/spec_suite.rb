class SpecSuite
  def run
    puts "Running #{self.class}"
    files.each do |file|
      require file
    end
  end

  def files
    raise NotImplementedError
  end
end

if $0 == __FILE__
  dir = File.dirname(__FILE__)
  raise "Failure" unless system("ruby #{dir}/main_spec_suite.rb")
  raise "Failure" unless system("ruby #{dir}/test_unit_spec_suite.rb")
  raise "Failure" unless system("ruby #{dir}/rspec_spec_suite.rb")
end
