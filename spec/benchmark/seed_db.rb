lib = File.expand_path('../../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'event_store'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on("-c","--connection","Connection string") do |c|
    options[:connection_string] = c
  end
end.parse!

if !options[:connection_string]
  puts "You need to set connection string with the -c flag"
  puts "Ex. ruby bench.rb -c vertica://user:pw@host:port/db_name"
  exit 1
end

EventStore.connect ARGV.first

ITERATIONS = 100_000
DEVICES = 30_000
EVENTS = 5_000_000
EVENT_TYPES = 100

event_types = Array.new(EVENT_TYPES) { |i| "event_type_#{i}" }

(1..DEVICES).each do |device_id|
  agg = EventStore::Aggregate.new(device_id, :device)
  (EVENTS/DEVICES).times do
    agg.event_class.create(aggregate_id: device_id, fully_qualified_name: event_types.sample, data: 9999999999999.to_s(2), occurred_at: DateTime.now)
  end
  EventStore::SnapshotCreator.new(agg).create_snapshot!
end
