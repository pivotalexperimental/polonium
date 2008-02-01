module Polonium
  class Driver < ::Selenium::SeleniumDriver
    include WaitFor
    attr_reader :server_host, :server_port

    # The Configuration object.
    def configuration
      Configuration.instance
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
      Element.new(self, locator)
    end

    def page
      Page.new(self)
    end

    # Open the home page of the Application and wait for the page to load.
    def open_home_page
      open(configuration.browser_url)
    end

    #--------- Commands
    alias_method :confirm, :get_confirmation

    # Type text into a page element
    def type(locator, value)
      assert_element_present(locator)
      super
    end

    def click(locator)
      assert_element_present locator
      super
    end

    def select(select_locator, option_locator)
      assert_element_present select_locator
      super
    end

    # Reload the current page that the browser is on.
    def reload
      get_eval("selenium.browserbot.getCurrentWindow().location.reload()")
    end

    # Click a link and wait for the page to load.
    def click_and_wait(locator, wait_for = default_timeout)
      click locator
      assert_page_loaded(wait_for)
    end

    # Click the back button and wait for the page to load.
    def go_back_and_wait
      go_back
      assert_page_loaded
    end

    # Open the home page of the Application and wait for the page to load.
    def open(url)
      super
      assert_page_loaded
    end
    alias_method :open_and_wait, :open

    # Get the inner html of the located element.
    def get_inner_html(locator)
      get_eval(inner_html_js(locator))
    end

    # Does the element at locator not contain the text?
    def element_does_not_contain_text(locator, text)
      return true unless is_element_present(locator)
      return !element(locator).contains?(text)
    end

    #----- Waiting for conditions
    def assert_element_present(locator, params={})
      params = {
        :message => "Expected element '#{locator}' to be present, but it was not"
      }.merge(params)
      wait_for(params) do
        is_element_present(locator)
      end
    end

    def assert_element_not_present(locator, params={})
      params = {
        :message => "Expected element '#{locator}' to be absent, but it was not"
      }.merge(params)
      wait_for(:message => params[:message]) do
        !is_element_present(locator)
      end
    end

    def wait_for_page_to_load(timeout=default_timeout)
      super
      if get_title.include?("Exception caught")
        flunk "We got a new page, but it was an application exception page.\n\n#{get_html_source}"
      end
    end
    alias_method :assert_page_loaded, :wait_for_page_to_load

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
