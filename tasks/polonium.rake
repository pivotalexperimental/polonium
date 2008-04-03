namespace :selenium do
  desc "Run the selenium remote-control server"
  task :server do
    system('export MOZ_NO_REMOTE=1; selenium')
  end

  desc "Start the selenium servant (the server that launches browsers) on localhost"
  task :start_servant do
    system('export MOZ_NO_REMOTE=1; selenium')
  end
end
