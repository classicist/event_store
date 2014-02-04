require 'simplecov'
require 'simplecov-rcov'
require 'pry'

class SimpleCov::Formatter::MergedFormatter
  def format(result)
     SimpleCov::Formatter::HTMLFormatter.new.format(result)
     SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

SimpleCov.start do
  add_filter "/spec/"
  SimpleCov.minimum_coverage 95
end

require 'rspec'
require 'sequel'
require 'sequel/extensions/migration'
require 'event_store'

EventStore.create_db(:sqlite)
EventStore.redis_connect host: 'localhost'

RSpec.configure do |config|
  config.after(:each) do
    EventStore.db.from("#{EventStore.schema + '.' if EventStore.schema}device_events".lit).delete
    EventStore.redis.flushall
  end
end