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

    def method_missing(name, *args)
      return selenium_driver.send(name, *args)
    end

    protected
    delegate :open,
             :type,
             :wait_for_condition,
             :get_select_options,
             :get_selected_id,
             :get_selected_id,
             :get_selected_ids,
             :get_selected_index,
             :get_selected_indexes,
             :get_selected_label,
             :get_selected_labels,
             :get_selected_value,
             :get_selected_values,
             :get_body_text,
             :get_html_source,
             :to => :selenium_driver

    def should_stop_driver?
      return false unless configuration.test_browser_mode?
      configuration.stop_driver?(passed?)
    end
  end
end