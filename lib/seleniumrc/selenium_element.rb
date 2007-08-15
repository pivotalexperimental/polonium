module Seleniumrc
  class SeleniumElement
    attr_reader :locator
    
    def initialize(locator)
      @locator = locator
    end
  end
end