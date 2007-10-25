module SeleniumTestCaseSpec
  def base_selenium
    @base_selenium
  end
  
  class MySeleniumTestCase < Seleniumrc::SeleniumTestCase
    def initialize(*args)
      @_result = Test::Unit::TestResult.new
      super('test_nothing')
    end

    def run(result)
      # do nothing
    end
    def test_nothing
    end

    def base_selenium
      @selenium
    end
    def base_selenium=(value)
      @selenium = value
    end
  end
end
