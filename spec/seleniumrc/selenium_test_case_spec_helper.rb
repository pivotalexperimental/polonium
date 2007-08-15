module SeleniumTestCaseSpec
  def test_case
    test_case = MySeleniumTestCase.new
    time = Time.now
    time_class = "Time Class"
    mock(time_class).now.any_number_of_times.returns { time += 1 }
    stub(test_case).time_class.returns time_class
    stub(test_case).sleep.returns
    test_case
  end

  def base_selenium
    @base_selenium ||= begin
      @base_selenium = "Base Selenium"
      @test_case.base_selenium = @base_selenium
    end
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
