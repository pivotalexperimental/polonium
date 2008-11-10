require 'rubygems'
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
