require 'sequel'
require 'event_store/version'
require 'event_store/event_appender'
require 'event_store/aggregate'
require 'event_store/client'
require 'event_store/errors'

module EventStore
  Event = Struct.new(:aggregate_id, :occurred_at, :fully_qualified_name, :serialized_event)
  SerializedEvent = Struct.new(:fully_qualified_name, :serialized_event)

  def self.db
    @db
  end

  def self.connect(*args)
    @db = Sequel.connect(*args)
    @db.extension :pg_hstore
  end
end
