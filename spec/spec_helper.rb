require 'rubygems'
gem 'rspec', ">=0.7.5"
require 'spec'
require 'rr'

dir = File.dirname(__FILE__)
$LOAD_PATH << File.expand_path("#{dir}/../lib")

require "tmpdir"
require "hpricot"
require 'tempfile'

require "seleniumrc"
require File.dirname(__FILE__) + "/seleniumrc/selenium_test_case_spec_helper"

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

Spec::Runner.configure do |config|
  config.mock_with :rr
end

module Seleniumrc::WaitFor
  def time_class
    @time_class ||= FakeTimeClass.new
  end

  def sleep(time)
  end  
end

class FakeTimeClass
  def initialize
    @now = Time.now
  end

  def now
    @now += 1
  end
end