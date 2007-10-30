require 'socket'
require 'logger'
require "stringio"

require "active_record"

require 'net/http'
require 'test/unit'
require 'test/unit/testresult'
require 'test/unit/ui/testrunnermediator'

require "selenium"
require "seleniumrc/extensions/testrunnermediator"
require "seleniumrc/wait_for"
require "seleniumrc/selenium_driver"
require "seleniumrc/selenium_server_runner"
require "seleniumrc/mongrel_selenium_server_runner"
require "seleniumrc/webrick_selenium_server_runner"
require "seleniumrc/dsl/test_unit_dsl"
require "seleniumrc/dsl/selenium_dsl"
require "seleniumrc/selenium_configuration"
require "seleniumrc/selenium_page"
require "seleniumrc/selenium_element"
require "seleniumrc/selenium_test_case"
require "seleniumrc/tasks/selenium_test_task"

require 'webrick_server' if self.class.const_defined? :RAILS_ROOT
