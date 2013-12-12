require 'simplecov'
require 'simplecov-rcov'

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
  Sequel.connect('sqlite://db/event_store_test.db')
end

Sequel::Migrator.apply(test_db, File.expand_path('db/migrations'), 0)
Sequel::Migrator.apply(test_db, File.expand_path('db/migrations'))

EventStore.connect :adapter => :sqlite, :database => 'db/event_store_test.db'