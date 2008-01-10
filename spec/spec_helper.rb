require 'rubygems'
gem 'rspec', ">=1.1.0"
require 'spec'
require 'rr'

dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.expand_path("#{dir}/../lib"))

require "tmpdir"
require "hpricot"
require 'tempfile'

require "polonium"
require File.dirname(__FILE__) + "/polonium/test_case_spec_helper"

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

module Polonium::WaitFor
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

describe "Selenium", :shared => true do
  def result(response_text=nil)
    "OK,#{response_text}"
  end  
end
