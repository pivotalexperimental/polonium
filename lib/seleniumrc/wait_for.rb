module Seleniumrc
  module WaitFor
    Context = Struct.new(:message)
    # Poll continuously for the return value of the block to be true. You can use this to assert that a client side
    # or server side condition was met.
    #   wait_for do
    #     User.count == 5
    #   end
    def wait_for(params={})
      timeout = params[:timeout] || default_wait_for_time
      message = params[:message] || "Timeout exceeded"
      context = Context.new(message)
      begin_time = time_class.now
      while (time_class.now - begin_time) < timeout
        return if yield(context)
        sleep 0.25
      end
      flunk(context.message + " (after #{timeout} sec)")
      true
    end

    def default_wait_for_time
      5
    end

    def time_class
      Time
    end

#    def wait_for_page_to_load(timeout=default_timeout)
#      selenium.wait_for_page_to_load timeout
#      if selenium.get_title.include?("Exception caught")
#        flunk "We got a new page, but it was an application exception page.\n\n" + get_html_source
#      end
#    end

    # The default Selenium Core client side timeout.
    def default_timeout
      @default_timeout ||= 20000
    end
    attr_writer :default_timeout

    def flunk(message)
      raise Test::Unit::AssertionFailedError, message
    end
  end
end