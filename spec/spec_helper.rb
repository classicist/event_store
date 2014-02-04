require 'simplecov'
require 'simplecov-rcov'
require 'pry'

class SimpleCov::Formatter::MergedFormatter
  def format(result)
     SimpleCov::Formatter::HTMLFormatter.new.format(result)
     SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

SimpleCov.start do
  add_filter "/spec/"
  SimpleCov.minimum_coverage 95
end

require 'rspec'
require 'sequel'
require 'sequel/extensions/migration'
require 'event_store'

# def test_db
#   Sequel.connect('vertica://dbadmin:password@192.168.180.65:5433/nexia_history')
# end
# Sequel::Migrator.apply(test_db, File.expand_path('db/migrations'))

#To find the ip address of vertica on your local box (running in a vm)
#1. open Settings -> Network and select Wi-Fi
#2. open a terminal in the VM
#3. do /sbin/ifconfig (ifconfig is not in $PATH)
#4. the inet address for en0 is what you want

EventStore.connect :adapter => :vertica, :database => 'nexia_history', host: '192.168.180.86', username: 'dbadmin', password: 'password'
EventStore.redis_connect host: 'localhost'

RSpec.configure do |config|
  config.after(:each) do
    EventStore.db.from("events.device_events".lit).delete
    EventStore.redis.flushall
  end
end