require 'sequel'
require 'sequel/core'
require 'vertica'
require 'sequel-vertica'
require 'redis'
require 'hiredis'
require 'event_store/version'
require 'event_store/time_hacker'
require 'event_store/event_appender'
require 'event_store/aggregate'
require 'event_store/client'
require 'event_store/errors'
Sequel.extension :migration

module EventStore
  Event = Struct.new(:aggregate_id, :occurred_at, :fully_qualified_name, :serialized_event, :version)
  SerializedEvent = Struct.new(:fully_qualified_name, :serialized_event, :version, :occurred_at)
  SNAPSHOT_DELIMITER = "__NexEvStDelim__"

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

  def self.table_name
    @table_name ||= raw_db_config['table_name']
  end

  def self.fully_qualified_table
    @fully_qualified_table ||= Sequel.lit "#{schema}.#{table_name}"
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
    @adapter == 'vertica' ? binary_string.unpack('H*').join : EventStore.db.literal(binary_string.to_sequel_blob)
  end

  def self.unescape_bytea(binary_string)
    if @adapter == 'vertica'
      [binary_string].pack("H*")
    else
      unescaped = Sequel::Postgres::Adapter.unescape_bytea(binary_string)
      unescaped[0] == "'" && unescaped[-1] == "'" ? unescaped[1...-1] : unescaped #postgres adds an extra set of quotes when you insert it, Redis does not. Therefore we need to pull off the extra quotes if they are there
    end
  end

  def self.custom_config(database_config, redis_config, table_name = 'events', environment = 'production')
    self.redis_connect(redis_config)
    database_config = database_config.inject({}) {|memo, (k,v)| memo[k.to_s] = v; memo}
    redis_config    = redis_config.inject({}) {|memo, (k,v)| memo[k.to_s] = v; memo}

    @adapter        = database_config['adapter'].to_s
    @environment    = environment
    @db_config      = database_config
    @table_name     = table_name
    create_db
  end

  def self.migrations_dir
     @adapter == 'vertica' ? 'migrations' : 'pg_migrations'
  end

  def self.create_db
    self.connect(@db_config)
    schema_exits = @db.table_exists?("#{schema}__schema_info".to_sym)
    @db.run "CREATE SCHEMA #{EventStore.schema};" unless schema_exits
    Sequel::Migrator.run(@db, File.expand_path(File.join('..','..','db', self.migrations_dir), __FILE__), :table=> "#{schema}__schema_info".to_sym)
  end

  def self.vertica_host
    File.read File.expand_path(File.join('..','..','db', 'vertica_host_address.txt'), __FILE__)
  end
end