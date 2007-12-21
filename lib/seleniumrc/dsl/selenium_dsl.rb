module Polonium
  module SeleniumDsl
    # The SeleniumConfiguration object.
    def configuration
      @configuration ||= SeleniumConfiguration.instance
    end
    attr_writer :configuration
    attr_accessor :selenium_driver  
    include WaitFor
    include TestUnitDsl

    # Download a file from the Application Server
    def download(path)
      uri = URI.parse(configuration.browser_url + path)
      puts "downloading #{uri.to_s}"
      Net::HTTP.get(uri)
    end

    # Open the home page of the Application and wait for the page to load.
    def open_home_page
      selenium_driver.open(configuration.browser_url)
    end

    protected
    SeleniumDriver.public_instance_methods(false).each do |method_name|
      delegate method_name, :to => :selenium_driver
    end

    def should_stop_driver?
      return false unless configuration.test_browser_mode?
      configuration.stop_driver?(passed?)
    end
  end
end