module SeleniumTestCaseSpec
  def self.test_case
    test_case = MySeleniumTestCase.new
    time = Time.now
    time_class = Spec::Mocks::Mock.new("time_class", {})
    time_class.should_receive(:now).any_number_of_times.and_return { time += 1 }
    test_case.stub!(:time_class).and_return time_class
    test_case.stub!(:sleep).and_return
    test_case
  end

  def base_selenium
    @base_selenium ||= begin
      @base_selenium = mock("Base Selenium")
      @test_case.base_selenium = @base_selenium
    end
  end

  class MySeleniumTestCase < SeleniumrcFu::SeleniumTestCase
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
