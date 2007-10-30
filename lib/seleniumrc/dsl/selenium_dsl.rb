module Seleniumrc
  module SeleniumDsl
    # The SeleniumConfiguration object.
    def configuration
      @configuration ||= SeleniumConfiguration.instance
    end
    attr_writer :configuration
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
      selenium.open(configuration.browser_url)
    end

    def method_missing(name, *args)
      return selenium.send(name, *args)
    end

    protected
    attr_accessor :selenium
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
             :to => :selenium

    def should_stop_selenese_interpreter?
      return false unless configuration.test_browser_mode?
      configuration.stop_selenese_interpreter?(passed?)
    end
  end
end