module Seleniumrc
  class SeleniumDriver < ::Selenium::SeleniumDriver
    include WaitFor
    attr_reader :server_host, :server_port

    def type(locator, value)
      element(locator).is_present
      super
    end

    # Reload the current page that the browser is on.
    def reload
      get_eval("selenium.browserbot.getCurrentWindow().location.reload()")
    end

    def click(locator)
      element(locator).is_present
      super
    end
    alias_method :wait_for_and_click, :click

    def select(select_locator,option_locator)
      element(select_locator).is_present
      super
    end

    def browser_start_command
      @browserStartCommand
    end

    def browser_url
      @browserURL
    end

    def timeout_in_milliseconds
      @timeout
    end

    alias_method :confirm, :get_confirmation

    def insert_javascript_file(uri)
      js = <<-USEREXTENSIONS
      var headTag = document.getElementsByTagName("head").item(0);
      var scriptTag = document.createElement("script");
      scriptTag.src = "#{uri}";
      headTag.appendChild( scriptTag );
      USEREXTENSIONS
      get_eval(js)
    end

    def insert_user_extensions
      insert_javascript_file("/selenium/user-extensions.js")
    end

    def element(locator)
      SeleniumElement.new(self, locator)
    end

    def page
      SeleniumPage.new(self)
    end

    #--------- Commands
    # Click a link and wait for the page to load.
    def click_and_wait(locator, wait_for = default_timeout)
      click locator
      wait_for_page_to_load(wait_for)
    end
    alias_method :click_and_wait_for_page_to_load, :click_and_wait

    # Click the back button and wait for the page to load.
    def go_back_and_wait
      go_back
      wait_for_page_to_load
    end

    # Open the home page of the Application and wait for the page to load.
    def open(url)
      super
      wait_for_page_to_load
    end
    alias_method :open_and_wait, :open

    # Get the inner html of the located element.
    def get_inner_html(locator)
      get_eval(inner_html_js(locator))
    end

    # Does the element at locator contain the text?
    def element_contains_text(locator, text)
      is_element_present(locator) && get_inner_html(locator).include?(text)
    end

    # Does the element at locator not contain the text?
    def element_does_not_contain_text(locator, text)
      return true unless is_element_present(locator)
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
      super
      if get_title.include?("Exception caught")
        flunk "We got a new page, but it was an application exception page.\n\n" + get_html_source
      end
    end

    def wait_for_element_to_contain(locator, text, message=nil, timeout=default_wait_for_time)
      wait_for(:message => message, :timeout => timeout) do
        element_contains_text(locator, text)
      end
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

    def inner_html_js(locator)
      %Q|this.page().findElement("#{locator}").innerHTML|
    end
  end
end
