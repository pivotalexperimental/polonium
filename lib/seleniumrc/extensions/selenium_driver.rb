module Selenium
  class SeleniumDriver
    attr_reader :server_host, :server_port

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
  end
end
