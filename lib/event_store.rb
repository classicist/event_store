require 'sequel'
require 'sequel/core'
require 'vertica'
require 'sequel-vertica'
require 'redis'
require 'hiredis'
require 'event_store/version'
require 'event_store/time_hacker'
require 'event_store/event_stream'
require 'event_store/snapshot'
require 'event_store/aggregate'
require 'event_store/client'
require 'event_store/errors'
require 'yaml'

Sequel.extension :migration

module EventStore
  Event = Struct.new(:aggregate_id, :occurred_at, :fully_qualified_name, :sub_key, :serialized_event)
  SerializedEvent = Struct.new(:fully_qualified_name, :serialized_event, :event_id, :occurred_at)
  SNAPSHOT_DELIMITER     = "__NexEvStDelim__"
  SNAPSHOT_KEY_DELIMITER = ":"
  NO_SUB_KEY              = "NO_SUB_KEY"

  def self.db_config
    raw_db_config[@environment.to_s][@adapter.to_s]
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
    @db ||= Sequel.connect(*args)
  end

  def self.redis_connect(config_hash)
    @redis ||= Redis.new(config_hash)
  end

  def self.local_redis_config
    @redis_connection ||= raw_db_config['redis']
  end

  def self.schema
    @schema ||= raw_db_config[@environment][@adapter]['schema']
  end

  def self.insert_table_name(date)
    return fully_qualified_table unless partitioning?

    partition_name = date.strftime("#{table_name}#{partition_name_suffix}")
    qualified_table_name(partition_name)
  end

  def self.partitioning?
    @db_config["partitioning"]
  end

  def self.partition_name_suffix
    @db_config["partition_name_suffix"]
  end

  def self.table_name
    @table_name ||= raw_db_config['table_name']
  end

  def self.lookup_table_name
    @lookup_table_name ||= raw_db_config['lookup_table_name'] || "fully_qualified_names"
  end

  def self.fully_qualified_table
    @fully_qualified_table ||= qualified_table_name
  end

  def self.qualified_table_name(name = table_name)
    Sequel.lit "#{schema}.#{name}"
  end

  def self.fully_qualified_names_table
    @fully_qualified_names_table ||= Sequel.lit "#{schema}.#{lookup_table_name}"
  end

  def self.connected?
    !!EventStore.db
  end

  def self.clear!
    return unless connected?
    EventStore.db.from(fully_qualified_table).delete
    EventStore.redis.flushdb
  end

  def self.postgres(environment = 'test', table_name = 'events', schema = 'event_store_test')
    @schema         = schema
    @table_name     = table_name
    @environment    = environment.to_s
    @adapter        = 'postgres'
    @db_config      ||= self.db_config
    custom_config(@db_config, local_redis_config, @table_name, environment)
  end

  #To find the ip address of vertica on your local box (running in a vm)
  #1. open Settings -> Network and select Wi-Fi
  #2. open a terminal in the VM
  #3. do /sbin/ifconfig (ifconfig is not in $PATH)
  #4. the inet address for en0 is what you want
  #Hint: if it just hangs, you have have the wrong IP
  def self.vertica(environment = 'test', table_name = 'events', schema = 'event_store_test')
    @schema         = schema
    @table_name     = table_name
    @environment    = environment.to_s
    @adapter        = 'vertica'
    @db_config      ||= self.db_config
    @db_config['host'] ||= ENV['VERTICA_HOST'] || vertica_host
    custom_config(@db_config, local_redis_config, @table_name, environment)
  end

  def self.escape_bytea(binary_string)
    binary_string.unpack('H*').join
  end

  def self.unescape_bytea(binary_string)
    [binary_string].pack("H*")
  end

  def self.custom_config(database_config, redis_config, table_name = 'events', environment = 'production')
    self.redis_connect(redis_config)
    database_config = database_config.inject({}) {|memo, (k,v)| memo[k.to_s] = v; memo}
    redis_config    = redis_config.inject({}) {|memo, (k,v)| memo[k.to_s] = v; memo}

    @adapter        = database_config["adapter"].to_s
    @environment    = environment
    @db_config      = database_config
    @table_name     = table_name
    @schema         = database_config["schema"].to_s
    @use_names_table = database_config.fetch("use_names_table", true)
    connect_db
  end

  def self.use_names_table?
    @use_names_table
  end

  def self.migrations_dir
    @adapter == 'vertica' ? 'migrations' : 'pg_migrations'
  end

  def self.connect_db
    self.connect(@db_config)
  end

  def self.create_db
    connect_db
    table = "#{schema}__schema_info".to_sym
    @db.run("CREATE SCHEMA IF NOT EXISTS #{schema}")
    Sequel::Migrator.run(@db, File.expand_path(File.join('..','..','db', self.migrations_dir), __FILE__), table: table)
  end

  def self.vertica_host
    File.read File.expand_path(File.join('..','..','db', 'vertica_host_address.txt'), __FILE__)
  end
end
