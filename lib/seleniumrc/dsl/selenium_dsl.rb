module Seleniumrc
  module SeleniumDsl
    # The SeleniumConfiguration object.
    def configuration
      @configuration ||= SeleniumConfiguration.instance
    end
    attr_writer :configuration
    include WaitFor
    include TestUnitDsl

    def type(locator,value)
      element(locator).is_present
      selenium.type(locator,value)
    end

    def click(locator)
      element(locator).is_present
      selenium.click(locator)
    end

    alias_method :wait_for_and_click, :click

    # Download a file from the Application Server
    def download(path)
      uri = URI.parse(configuration.browser_url + path)
      puts "downloading #{uri.to_s}"
      Net::HTTP.get(uri)
    end

    def select(select_locator,option_locator)
      element(select_locator).is_present
      selenium.select(select_locator,option_locator)
    end

    # Reload the current page that the browser is on.
    def reload
      selenium.get_eval("selenium.browserbot.getCurrentWindow().location.reload()")
    end

    def method_missing(name, *args)
      return selenium.send(name, *args)
    end


#--------- Commands

    # Open a location and wait for the page to load.
    def open_and_wait(url)
      page.open_and_wait url
    end

    # Click a link and wait for the page to load.
    def click_and_wait(locator, wait_for = default_timeout)
      selenium.click locator
      wait_for_page_to_load(wait_for)
    end
    alias_method :click_and_wait_for_page_to_load, :click_and_wait

    # Click the back button and wait for the page to load.
    def go_back_and_wait
      selenium.go_back
      wait_for_page_to_load
    end

    # Open the home page of the Application and wait for the page to load.
    def open_home_page
      selenium.open(configuration.browser_url)
      wait_for_page_to_load
    end

    # Get the inner html of the located element.
    def get_inner_html(locator)
      element(locator).inner_html
    end

    # Does the element at locator contain the text?
    def element_contains_text(locator, text)
      selenium.is_element_present(locator) && get_inner_html(locator).include?(text)
    end

    # Does the element at locator not contain the text?
    def element_does_not_contain_text(locator, text)
      return true unless selenium.is_element_present(locator)
      return !get_inner_html(locator).include?(text)
    end

    # Does locator element have text fragments in a certain order?
    def is_text_in_order(locator, *text_fragments)
      container = Hpricot(get_text(locator))

      everything_found = true
      wasnt_found_message = "Certain fragments weren't found:\n"

      everything_in_order = true
      wasnt_in_order_message = "Certain fragments were out of order:\n"

      text_fragments.inject([-1, nil]) do |old_results, new_fragment|
        old_index = old_results[0]
        old_fragment = old_results[1]
        new_index = container.inner_html.index(new_fragment)

        unless new_index
          everything_found = false
          wasnt_found_message << "Fragment #{new_fragment} was not found\n"
        end

        if new_index < old_index
          everything_in_order = false
          wasnt_in_order_message << "Fragment #{new_fragment} out of order:\n"
          wasnt_in_order_message << "\texpected '#{old_fragment}'\n"
          wasnt_in_order_message << "\tto come before '#{new_fragment}'\n"
        end

        [new_index, new_fragment]
      end

      wasnt_found_message << "\n\nhtml follows:\n #{container.inner_html}\n"
      wasnt_in_order_message << "\n\nhtml follows:\n #{container.inner_html}\n"

      unless everything_found && everything_in_order
        yield(everything_found, wasnt_found_message, everything_in_order, wasnt_in_order_message)
      end
    end
#----- Waiting for conditions

    def wait_for_page_to_load(timeout=default_timeout)
      selenium.wait_for_page_to_load timeout
      if get_title.include?("Exception caught")
        flunk "We got a new page, but it was an application exception page.\n\n" + get_html_source
      end
    end

    def wait_for_element_to_contain(locator, text, message=nil, timeout=default_wait_for_time)
      wait_for({:message => message, :timeout => timeout}) {element_contains_text(locator, text)}
    end
    alias_method :wait_for_element_to_contain_text, :wait_for_element_to_contain

    # Open the log window on the browser. This is useful to diagnose issues with Selenium Core.
    def show_log(log_level = "debug")
      get_eval "LOG.setLogLevelThreshold('#{log_level}')"
    end

    # Slow down each Selenese step after this method is called.
    def slow_mode
      get_eval "slowMode = true"
      get_eval 'window.document.getElementsByName("FASTMODE")[0].checked = true'
    end

    # Speeds up each Selenese step to normal speed after this method is called.
    def fast_mode
      get_eval "slowMode = false"
      get_eval 'window.document.getElementsByName("FASTMODE")[0].checked = false'
    end

    def page
      SeleniumPage.new(@selenium)
    end

    def element(locator)
      SeleniumElement.new(@selenium, locator)
    end

    protected
    attr_accessor :selenium
    delegate :open,
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