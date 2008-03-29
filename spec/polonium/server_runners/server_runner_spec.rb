require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper")

module Polonium
  module ServerRunners
    describe ServerRunner do
      before(:each) do
        @runner = ServerRunner.new(Configuration.new)
        class << @runner
          public :start_server, :stop_server
        end
      end

      it "should initialize started? to be false" do
        @runner.started?.should ==  false
      end

      it "start method should start new thread and set started" do
        mock(@runner).start_server
        stub(@runner).stop_server
        @runner.start
      end

      it "stop method should set started? to false" do
        def @runner.stop_server;
        end
        @runner.instance_eval {@started = true}
        @runner.stop
        @runner.started?.should ==  false
      end

      it "start_server method should raise a NotImplementedError by default" do
        proc {@runner.start_server}.should raise_error(NotImplementedError)
      end
    end
  end
end
