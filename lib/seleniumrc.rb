require 'socket'
require 'logger'
require "stringio"

require "active_record"

require 'net/http'
require 'test/unit'
require 'test/unit/testresult'
require 'test/unit/ui/testrunnermediator'

require "selenium"
require "seleniumrc/extensions/module"
require "seleniumrc/extensions/testrunnermediator"
require "seleniumrc/wait_for"
require "seleniumrc/driver"
require "seleniumrc/runner"
require "seleniumrc/mongrel_selenium_server_runner"
require "seleniumrc/webrick_selenium_server_runner"
require "seleniumrc/dsl/test_unit_dsl"
require "seleniumrc/dsl/selenium_dsl"
require "seleniumrc/configuration"
require "seleniumrc/page"
require "seleniumrc/element"
require "seleniumrc/test_case"
require "seleniumrc/tasks/selenium_test_task"

require 'webrick_server' if self.class.const_defined? :RAILS_ROOT
