module SeleniumTestCaseSpec
  def stub_wait_for(subject)
    time = Time.now
    time_class = "Time Class"
    stub(time_class).now.returns { time += 1 }
    stub(subject).time_class.returns time_class
    stub(subject).sleep.returns
    subject
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
