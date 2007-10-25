class Test::Unit::AutoRunner
  class << self
    alias_method :run_without_seleniumrc, :run
    def run_with_seleniumrc
      runner = Seleniumrc::SeleniumConfiguration.instance.create_server_runner
      runner.start
      begin
        passed = run_without_seleniumrc
        Seleniumrc::SeleniumConfiguration.instance.stop_interpreter_if_necessary(passed)
        return passed
      ensure
        runner.stop
      end
    end
    alias_method :run, :run_with_seleniumrc
  end
end