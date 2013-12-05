require 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'sequel'
require 'sequel/extensions/migration'
require 'event_store'

def test_db
  Sequel.connect('sqlite://db/event_store_test.db')
end

Sequel::Migrator.apply(test_db, File.expand_path('db/migrations'))

EventStore.configure do
  db :sqlite
end

# after all tests teardown
Minitest.after_run { Sequel::Migrator.apply(Sequel::Model.db, File.expand_path('db/migrations'), 0) }

