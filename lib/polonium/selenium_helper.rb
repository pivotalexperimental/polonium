# Expand the path to environment so that Ruby does not load it multiple times
# File.expand_path can be removed if Ruby 1.9 is in use.
if (Object.const_defined?(:ActiveRecord) && !ActiveRecord::Base.allow_concurrency)
  raise "Since Selenium spawns an internal app server, we need ActiveRecord to be multi-threaded. Please set 'ActiveRecord::Base.allow_concurrency = true' in your environment file (e.g. test.rb)."
end
