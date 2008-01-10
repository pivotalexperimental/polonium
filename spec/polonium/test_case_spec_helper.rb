module TestCaseSpecHelper
  attr_reader :base_selenium
  
  class MySeleniumTestCase < Polonium::TestCase
    def initialize(*args)
      @_result = Test::Unit::TestResult.new
      super('test_nothing')
    end

    def run(result)
      # do nothing
    end
    def test_nothing
    end
  end
end
