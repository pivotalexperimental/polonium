module Seleniumrc
  class SeleniumPage
    include WaitFor
    attr_reader :selenium

    def initialize(selenium)
      @selenium = selenium
    end

    def has_title(expected_title, params = {})
      wait_for(params) do |context|
        actual = selenium.get_title
        context.message = "Expected title '#{expected_title}' but was '#{actual}'"
        expected_title == actual
      end
    end

    def ==(other)
      return false unless other.is_a?(SeleniumPage)
      self.selenium == other.selenium
    end
  end
end