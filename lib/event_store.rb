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

  def self.sqlite
    redis_connect host: 'localhost'
    create_db(:sqlite)
  end

  def self.postgres(test = true)
    redis_connect host: 'localhost'
    create_db(:postgres, test)
  end

  def self.create_db(type, test = true, db_config = nil)
    test_db = '_test' if test
    if type == :sqlite
      EventStore.connect :adapter => :sqlite
      begin
        @db.run 'DROP TABLE device_events;'
      rescue
        #don't care if this fails bc it fails if there is no table, which is what we want
      end
        @@schema = nil
        @db.run event_table_creation_ddl(type)
    elsif type == :postgres
      EventStore.connect :adapter => :postgres, :database => "nexia_history#{test_db}",
        host: 'localhost', username: 'nexia', password: 'Password1', encoding: 'UTF-8',
        pool: 100, reconnect: true, port: 5432

      `bundle exec sequel -m db/pg_migrations postgres://nexia:Password1@localhost:5432/nexia_history#{test_db}`
    elsif type == :vertica
      #To find the ip address of vertica on your local box (running in a vm)
      #1. open Settings -> Network and select Wi-Fi
      #2. open a terminal in the VM
      #3. do /sbin/ifconfig (ifconfig is not in $PATH)
      #4. the inet address for en0 is what you want
      EventStore.connect :adapter => :vertica, :database => "nexia_history#{test_db}", host: vertica_host, username: 'dbadmin', password: 'password'
      `bundle exec sequel -m db/migrations vertica://dbadmin:password@#{vertica_host}:5433/nexia_history#{test_db}`
    end
  end

  def self.vertica_host
    File.read File.expand_path("../../db/vertica_host_address.txt", __FILE__)
  end

  def self.event_table_creation_ddl(type)
    if type == :sqlite
    %Q<CREATE TABLE IF NOT EXISTS device_events (
      id AUTO_INCREMENT PRIMARY KEY,
      version BIGINT NOT NULL,
      aggregate_id varchar(36) NOT NULL,
      fully_qualified_name varchar(255) NOT NULL,
      occurred_at DATETIME NOT NULL,
      serialized_event VARBINARY(255) NOT NULL);>
    elsif type == :vertica
      %Q<CREATE TABLE #{schema} device_events (
      id AUTO_INCREMENT PRIMARY KEY,
      version BIGINT NOT NULL,
      aggregate_id varchar(36) NOT NULL,
      fully_qualified_name varchar(255) NOT NULL,
      occurred_at DATETIME NOT NULL,
      serialized_event VARBINARY(255) NOT NULL);>
    end
  end
end

#http://stackoverflow.com/questions/1114725/using-utc-with-sequel
module Sequel
    def self.string_to_datetime(string)
    begin
      if datetime_class == DateTime
        DateTime.parse(string, convert_two_digit_years)
      else
        Time.parse(string + " +00:00").utc
      end
    rescue => e
      raise convert_exception_class(e, InvalidValue)
    end
  end
end