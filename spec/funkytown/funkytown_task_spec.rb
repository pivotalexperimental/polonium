require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

class SampleFunkytownTask < Funkytown::FunkytownTask
  def check_requirements
  end
end

describe "Typical funkytown task setup", :shared => true do
  before(:each) do
    @task = new_funkytown_task
    @task.stub!(:servant_hosts).and_return(["localhost"])
    @task.stub!(:servant_port).and_return("port")
    @task.stub!(:say)
    @non_running_process = ProcessStub.new("localhost", "port")
    @non_running_process.is_running = false
    @running_process = ProcessStub.new("localhost", "port")
    @running_process.is_running = true
  end

  def new_funkytown_task(options = {})
    SampleFunkytownTask.new("railsenv", "railsroot", {}, options)
  end
end

describe "Funkytown Task initialization" do
  it_should_behave_like "Typical funkytown task setup"

  before do
    @default_options = {:jsunit_master_host => "masterhost"}
    Funkytown::FunkytownConfig.stub!(:load).and_return(Funkytown::FunkytownConfig.default_config.merge(@default_options))
  end

  it "should load options from Funkytown::FunkytownConfig if no options given" do
    task = new_funkytown_task
    task.instance_variable_get("@jsunit_master_host").should == "masterhost"
  end

  it "should not fail if servants not running by default" do
    task = new_funkytown_task
    task.fail_if_remote_servants_not_running.should be_false
  end

  it "should override options from Funkytown::FunkytownConfig if given" do
    task = new_funkytown_task(:jsunit_master_host => "myotherhost")
    task.instance_variable_get("@jsunit_master_host").should == "myotherhost"
  end

  it "should output the options to System" do
    expected_options = @default_options.merge(:jsunit_master_host => "myotherhost")
    SYSTEM.should_receive(:say).once.with(/Options .*jsunit_master_host: myotherhost.*/m, :when_verbose => true)
    task = new_funkytown_task(:jsunit_master_host => "myotherhost")
  end
end

describe "Funkytown Task run_servant" do
  it_should_behave_like "Typical funkytown task setup"

  it "should launch the servant if the process isn't running yet and the servant host is localhost" do
    @task.stub!(:servant_process).and_return(@non_running_process)
    Funkytown::System.stub!(:wait_for).and_return {@non_running_process.is_running = true}
    @non_running_process.should_receive(:start).once
    @task.run_servant("localhost")
    @non_running_process.should be_is_running
  end

  it "should fail gracefully if the start process doesn't work" do
    @task.stub!(:servant_process).and_return(@non_running_process)
    Funkytown::System.stub!(:wait_for).and_return {raise "Unable to start the process (after 50 sec)"}
    @non_running_process.should_receive(:start).once
    lambda {@task.run_servant("localhost")}.should raise_error(RuntimeError, "Unable to start the process (after 50 sec)")
    @non_running_process.should_not be_is_running
  end

  it "should not launch the servant if the process isn't running yet and the servant host is not localhost" do
    @non_running_process.host = "iamnotlocalhost"
    @task.stub!(:servant_process).and_return(@non_running_process)
    @non_running_process.should_not_receive(:start)
    @task.run_servant("iamnotlocalhost")
  end

  it "should not launch the servant if the process is already running" do
    @task.stub!(:servant_process).and_return(@running_process)
    @running_process.should_not_receive(:start)
    @task.run_servant("localhost")
  end
end

describe "Funkytown Task check_servants" do
  it_should_behave_like "Typical funkytown task setup"

  it "should start localhost if localhost is not running" do
    @task.stub!(:say)
    @task.stub!(:servant_hosts).and_return(["localhost"])
    @task.stub!(:servant_process).and_return(@non_running_process)

    @task.should_receive(:run_servant).with("localhost")
    @task.check_servants
  end

  it "should NOT start localhost if localhost is running" do
    @task.stub!(:say)
    @task.stub!(:servant_hosts).and_return(["localhost"])
    @task.stub!(:servant_process).and_return(@running_process)

    @task.should_not_receive(:run_servant)
    @task.check_servants
  end

  it "should remove non-running remote servants if fail_if_remote_servants_not_running is false" do
    @task.stub!(:servant_hosts).and_return(["remote1", "remote2"])
    @task.fail_if_remote_servants_not_running = false
    @task.should_receive(:say).ordered.with("checking remote1")
    @task.should_receive(:say).ordered.with("checking remote2")
    @task.should_receive(:say).ordered.with("Warning: Servant not found on remote2")
    @task.should_receive(:say).ordered.with("done checking")
    @task.should_receive(:servant_process).with("remote1").and_return(@running_process)
    @task.should_receive(:servant_process).with("remote2").and_return(@non_running_process)

    @task.check_servants
    @task.servant_hosts.should == ["remote1"]
  end

  it "should fail if remote servant not run and fail_if_remote_servants_not_running is true" do
    @task.stub!(:servant_hosts).and_return(["remote1", "remote2"])
    @task.fail_if_remote_servants_not_running = true
    @task.stub!(:say)
    @task.should_receive(:servant_process).with("remote1").and_return(@running_process)
    @task.should_receive(:servant_process).with("remote2").and_return(@non_running_process)

    lambda {@task.check_servants}.should raise_error(RuntimeError, "Servant not found on remote2")
  end

end