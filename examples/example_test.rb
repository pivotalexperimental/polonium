require File.dirname(__FILE__) + "/selenium_helper"

class ExampleTest < SeleniumTestCase

  def test_home_page
    open_home_page
    assert_text_present "Welcome to Polonium"
  end
end
