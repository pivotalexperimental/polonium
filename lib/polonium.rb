require 'rubygems'
require 'socket'
require 'logger'
require "stringio"
require "resolv-replace"

require "active_record"

require 'net/http'
require 'test/unit'
require 'test/unit/testresult'
require 'test/unit/ui/testrunnermediator'

require "selenium"
require "polonium/extensions/module"
require "polonium/wait_for"
require "polonium/driver"
require "polonium/server_runners/server_runner"
require "polonium/server_runners/mongrel_server_runner"
require "polonium/server_runners/webrick_server_runner"
require "polonium/dsl/selenium_dsl"
require "polonium/configuration"
require "polonium/values_match"
require "polonium/page"
require "polonium/element"
require "polonium/test_case"
require "polonium/tasks/selenium_test_task"

require 'webrick_server' if self.class.const_defined? :RAILS_ROOT

require "polonium/adapters/test_unit"
if Object.const_defined?(:Spec)
  require "polonium/adapters/rspec"
end
