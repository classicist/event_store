require 'sequel'
require 'vertica'
require 'sequel-vertica'
require 'redis'
require 'event_store/version'
require 'event_store/event_appender'
require 'event_store/aggregate'
require 'event_store/client'
require 'event_store/errors'

module EventStore
  Event = Struct.new(:aggregate_id, :occurred_at, :fully_qualified_name, :serialized_event, :version)
  SerializedEvent = Struct.new(:fully_qualified_name, :serialized_event, :version, :occurred_at)
  SNAPSHOT_DELIMITER = "__NexEvStDelim__"
  @@schema = 'events'

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

  def self.clear!
    EventStore.db.from(Sequel.lit "#{EventStore.schema + '.' if EventStore.schema}device_events").delete
    EventStore.redis.flushall
  end

  def self.schema
    @@schema
  end

  def self.create_db(type, schema = nil)
    if type == :sqlite
      EventStore.connect :adapter => :sqlite, :database => 'db/nexia_history', host: 'localhost'
      begin
        @@schema = nil #sqlite does not use schemas
        @db.run 'DROP TABLE device_events;'
      rescue
        #don't care if this fails bc it fails if there is no table, which is what we want
      end
        @db.run event_table_creation_ddl(:sqlite)
    elsif type == :vertica
      #To find the ip address of vertica on your local box (running in a vm)
      #1. open Settings -> Network and select Wi-Fi
      #2. open a terminal in the VM
      #3. do /sbin/ifconfig (ifconfig is not in $PATH)
      #4. the inet address for en0 is what you want
      EventStore.connect :adapter => :vertica, :database => 'nexia_history', host: vertica_host, username: 'dbadmin', password: 'password'
      `bundle exec sequel -m db/migrations vertica://dbadmin:password@#{vertica_host}:5433/nexia_history`
    end
  end

  def self.vertica_host
    File.read File.expand_path("../../db/vertica_host_address.txt", __FILE__)
  end

  def self.event_table_creation_ddl(type=:sqlite)
    %Q<CREATE TABLE #{'IF NOT EXISTS' if type == :sqlite} #{schema + '.' if schema} device_events (
      id AUTO_INCREMENT PRIMARY KEY,
      version BIGINT NOT NULL,
      aggregate_id varchar(36) NOT NULL,
      fully_qualified_name varchar(255) NOT NULL,
      occurred_at DATETIME NOT NULL,
      serialized_event VARBINARY(255) NOT NULL);>
  end
end
