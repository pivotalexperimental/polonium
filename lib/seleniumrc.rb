require 'socket'
require 'logger'
require "stringio"

require "active_record"

require 'net/http'
require 'test/unit'
require 'test/unit/testresult'

require "selenium"
require "seleniumrc/extensions/selenese_interpreter"
require "seleniumrc/app_server_checker"
require "seleniumrc/selenium_server_runner"
require "seleniumrc/mongrel_selenium_server_runner"
require "seleniumrc/webrick_selenium_server_runner"
require "seleniumrc/selenium_context"
require "seleniumrc/selenium_configuration"
require "seleniumrc/selenium_element"
require "seleniumrc/selenium_dsl"
require "seleniumrc/selenium_test_case"
require "seleniumrc/tasks/selenium_test_task"

require 'webrick_server' if self.class.const_defined? :RAILS_ROOT
