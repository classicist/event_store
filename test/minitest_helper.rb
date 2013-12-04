require 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'sequel'
require 'sequel/extensions/migration'

def test_db
  Sequel.connect('sqlite://db/event_store_test.db')
end

Sequel::Migrator.apply(test_db, File.expand_path('db/migrations'))

# after all tests teardown
Minitest.after_run { Sequel::Migrator.apply(EventStore.db, File.expand_path('db/migrations'), 0) }

