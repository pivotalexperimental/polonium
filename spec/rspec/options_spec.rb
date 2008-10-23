require File.expand_path("#{File.dirname(__FILE__)}/rspec_spec_helper")

describe Spec::Runner::Options do
  describe "#run_example" do
    attr_reader :configuration, :app_server_runner, :the_rspec_options
    before do
      @original_configuration = Polonium::Configuration.instance
      @configuration = Polonium::Configuration.new
      Polonium::Configuration.instance = configuration
      @the_rspec_options = Spec::Runner::Options.new(StringIO.new, StringIO.new)
      the_rspec_options.after_suite_parts.push(*Spec::Runner.options.after_suite_parts)

      configuration.app_server_engine = :mongrel
      @app_server_runner = configuration.create_app_server_runner
    end

    after do
      Polonium::Configuration.instance = @original_configuration
    end

    it "stops the app server app_server_runner when finished" do
      mock.proxy(app_server_runner).stop
      the_rspec_options.run_examples
    end

    it "stops the Selenium driver when finished" do
      mock.proxy(configuration).stop_driver_if_necessary(true)
      the_rspec_options.run_examples
    end
  end
end