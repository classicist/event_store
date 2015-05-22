require "simplecov"
require "simplecov-rcov"
require "ostruct"
require "rspec"

class SimpleCov::Formatter::MergedFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result)
    SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/bundle/"
  add_filter "lib/event_store.rb"
  SimpleCov.minimum_coverage 75
end

require "event_store"

# connect to the test db for the gem, create to ensure exists, delete and re-create
EventStore.postgres("test", "test_events", "event_store_gem_test")
EventStore.create_db
EventStore.clear!
EventStore.create_db

RSpec.configure do |config|
  config.after(:each) do
    EventStore.clear!
  end
end
