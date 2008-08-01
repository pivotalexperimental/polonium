dir = File.dirname(__FILE__)
require dir + "/../test_helper"
require 'selenium'
require "polonium"

class SeleniumTestCase < Test::Unit::TestCase
    include Polonium::SeleniumDsl
    
    delegate :select, :to => :selenium_driver

    def setup
       super
       @selenium_driver = configuration.driver       
    end

    def teardown
     selenium_driver.stop if stop_driver?
     super
   end

end

