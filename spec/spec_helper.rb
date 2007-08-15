require 'rubygems'
gem 'rspec', ">=0.7.5"
require 'spec'

dir = File.dirname(__FILE__)
$LOAD_PATH << File.expand_path("#{dir}/../lib")

require "tmpdir"
require "hpricot"
require 'tempfile'

require 'test/unit'
require 'test/unit/ui/console/testrunner'
require "seleniumrc_fu/extensions/test_runner_mediator"

require "selenium"
require File.dirname(__FILE__) + "/seleniumrc_fu/selenium_test_case_spec_helper"

Test::Unit.run = true

ProcessStub = Struct.new :host, :port, :name, :cmd, :logdir, :is_running unless Object.const_defined?(:ProcessStub)
ProcessStub.class_eval do
  def is_running?
    self.is_running
  end
  def say(msg, options = {})
  end
  def run
    false
  end
  def start
    self.is_running = true
  end
  def stop
    self.is_running = false
  end
end
