require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module Seleniumrc
describe AppServerChecker, "on local host" do
  attr_reader :configuration
  before(:each) do
    @configuration = Seleniumrc::SeleniumConfiguration.new
    @host = "0.0.0.0"
    configuration.internal_app_server_host = @host
    @port = 4000
    configuration.internal_app_server_port = @port
    @app_server_checker = configuration.create_app_server_checker
    @mock_tcp_socket_class = 'mock_tcp_socket_class'
    @app_server_checker.tcp_socket_class = @mock_tcp_socket_class
    @expected_translated_local_host_address = "127.0.0.1"
  end

  it "returns true for is_server_started? if server is running" do
    mock(@mock_tcp_socket_class).new(@expected_translated_local_host_address, @port)
    @app_server_checker.is_server_started?.should == (true)
  end

  it "returns false for is_server_started? if server is NOT running" do
    mock(@mock_tcp_socket_class).new.with(@expected_translated_local_host_address, @port) {raise SocketError}
    @app_server_checker.is_server_started?.should == (false)
  end
end

describe AppServerChecker, "on remote host" do
  attr_reader :configuration
  before(:each) do
    @configuration = Seleniumrc::SeleniumConfiguration.new
    @host = "some-remote-host"
    configuration.internal_app_server_host = @host
    @port = 4000
    configuration.internal_app_server_port = @port
    @app_server_checker = configuration.create_app_server_checker
    @mock_tcp_socket_class = 'mock_tcp_socket_class'
    @app_server_checker.tcp_socket_class = @mock_tcp_socket_class
  end

  it "returns true for is_server_started? if verify_remote_app_server_is_running_flag is false" do
    configuration.verify_remote_app_server_is_running = false
    @app_server_checker.is_server_started?.should == (true)
  end

  it "returns true for is_server_started? if server is running" do
    mock(@mock_tcp_socket_class).new.with(@host, @port)
    @app_server_checker.is_server_started?.should == (true)
  end

  it "raises exception if server is NOT running and verify_remote_app_server_is_running_flag is true" do
    configuration.verify_remote_app_server_is_running = true
    mock(@mock_tcp_socket_class).new.with(@host, @port) {raise SocketError}
    lambda {@app_server_checker.is_server_started?}.should raise_error(RuntimeError)
  end
end
end
