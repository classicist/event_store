require 'sequel'
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

  def self.local_redis_connect
    @redis_connection ||= redis_connect raw_db_config['redis']
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

  def self.clear!
    EventStore.db.from(fully_qualified_table).delete
    EventStore.redis.flushdb
  end

  def self.postgres(environment = 'test')
    local_redis_connect
    @adapter        = 'postgres'
    @environment    = environment.to_s
    @db_config      ||= self.db_config
    create_db
  end

  #To find the ip address of vertica on your local box (running in a vm)
  #1. open Settings -> Network and select Wi-Fi
  #2. open a terminal in the VM
  #3. do /sbin/ifconfig (ifconfig is not in $PATH)
  #4. the inet address for en0 is what you want
  #Hint: if it just hangs, you have have the wrong IP
  def self.vertica(environment = 'test')
    local_redis_connect
    @adapter             = 'vertica'
    @environment         = environment.to_s
    @db_config         ||= self.db_config
    @db_config['host'] ||= ENV['VERTICA_HOST'] || vertica_host
    create_db
  end

  def self.custom_config(database_config, redis_config, envrionment = 'production')
    self.redis_connect(redis_config)
    @adapter        = database_config['adapter'].to_s
    @environment    = envrionment
    @db_config      = database_config
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