namespace :selenium do
  desc "Run the selenium remote-control server"
  task :server do
    system('export MOZ_NO_REMOTE=1; selenium')
  end

  desc "Start the selenium servant (the server that launches browsers) on localhost"
  task :start_servant do
    system('export MOZ_NO_REMOTE=1; selenium')
  end

  desc "Runs Selenium tests"
  task :test do
    Dir["#{RAILS_ROOT}/test/selenium/**/*_test.rb"].each do |file|
      require file
    end
  end

  desc "Runs Selenium tests"
  task :spec do
    runner_code = <<-CODE
    Dir["#{RAILS_ROOT}/spec/selenium/**/*_spec.rb"].each do |file|
      require file
    end
    CODE
    system("ruby -e '#{runner_code}'")
  end
end
