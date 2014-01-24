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

def test_db
  Sequel.connect('postgres://localhost:5432/event_store_test')
end
Sequel::Migrator.apply(test_db, File.expand_path('db/migrations'))

EventStore.connect :adapter => :postgres, :database => 'event_store_test', host: 'localhost'

RSpec.configure do |config|
  config.after(:each) do
    EventStore.db.from(:device_events).delete
    EventStore.db.from(:device_snapshots).delete
  end
end