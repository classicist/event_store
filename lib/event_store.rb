require 'sequel'
require 'vertica'
require 'sequel-vertica'
require 'redis'
require 'event_store/version'
require 'event_store/event_appender'
require 'event_store/aggregate'
require 'event_store/client'
require 'event_store/errors'
Sequel.extension :migration

module EventStore
  Event = Struct.new(:aggregate_id, :occurred_at, :fully_qualified_name, :serialized_event, :version)
  SerializedEvent = Struct.new(:fully_qualified_name, :serialized_event, :version, :occurred_at)
  SNAPSHOT_DELIMITER = "__NexEvStDelim__"

  def self.db_config(env, adapter)
    raw_db_config[env.to_s][adapter.to_s]
  end

  def self.raw_db_config
    if @raw_db_config.nil?
      file_path = File.expand_path(__FILE__ + '/../../db/database.yml')
      @config_file = File.open(file_path,'r')
      @raw_db_config = YAML.load(@config_file)
      @config_file.close
    end
    @raw_db_config
  end

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

  def self.local_redis_connect
    redis_connect raw_db_config['redis']
  end

  def self.schema
    @schema ||= raw_db_config['schema']
  end

  def self.table_name
    @table_name ||= raw_db_config['table_name']
  end

  def self.fully_qualified_table
    table = "#{schema}.#{table_name}"
    @db_type == :sqlite ? table : Sequel.lit(table)
  end

  def self.clear!
    EventStore.db.from(fully_qualified_table).delete
    EventStore.redis.flushdb
  end

  def self.sqlite
    local_redis_connect
    create_db(:sqlite, :test)
  end

  def self.postgres(db_env = :test)
    local_redis_connect
    create_db(:postgres, db_env)
  end

  def self.vertica(db_env = :test)
    local_redis_connect
    create_db(:vertica, db_env)
  end

  def self.production(database_config, redis_config)
    self.redis_connect redis_config
    self.connect database_config
  end

  def self.create_db(type, db_env, db_config = nil)
    @db_type = type
    db_config ||= self.db_config(db_env, type)

    if type == :sqlite
      EventStore.connect db_config
      Sequel::Migrator.apply(@db, 'db/sqlite_migrations')
    elsif type == :postgres
      EventStore.connect db_config
      Sequel::Migrator.apply(@db, 'db/pg_migrations')
    elsif type == :vertica
      #To find the ip address of vertica on your local box (running in a vm)
      #1. open Settings -> Network and select Wi-Fi
      #2. open a terminal in the VM
      #3. do /sbin/ifconfig (ifconfig is not in $PATH)
      #4. the inet address for en0 is what you want
      #Hint: if it just hangs, you have have the wrong IP

      db_config['host'] = vertica_host
      EventStore.connect db_config
      Sequel::Migrator.apply(@db, 'db/migrations')
    end
  end

  def self.vertica_host
    File.read File.expand_path("../../db/vertica_host_address.txt", __FILE__)
  end
end