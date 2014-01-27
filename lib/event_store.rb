require 'sequel'
require 'redis'
require 'event_store/version'
require 'event_store/event_appender'
require 'event_store/aggregate'
require 'event_store/client'
require 'event_store/errors'

module EventStore
  Event = Struct.new(:aggregate_id, :occurred_at, :fully_qualified_name, :serialized_event)
  SerializedEvent = Struct.new(:fully_qualified_name, :serialized_event, :version)
  SNAPSHOT_DELIMITER = "__NexEvStDelim__"

  def self.db
    @db
  end

  def self.redis
    @redis
  end

  def self.connect(*args)
    @db = Sequel.connect(*args)
  end

  def self.redis_connect(config_hash)
    @redis = Redis.new(config_hash)
  end
end
