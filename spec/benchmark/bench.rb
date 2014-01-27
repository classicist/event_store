require 'event_store'
require 'benchmark'

# db_config = Hash[
#     :username => 'nexia',
#     :password => 'Password1',
#     host: 'ec2-54-221-80-232.compute-1.amazonaws.com',
#     encoding: 'utf8',
#     pool: 1000,
#     adapter: :postgres,
#     database: 'event_store_performance'
#   ]
# EventStore.connect ( db_config )
EventStore.connect :adapter => :postgres, :database => 'event_store_performance', host: 'localhost'
EventStore.redis_connect host: 'localhost'

ITERATIONS = 1000

Benchmark.bmbm do |x|
  x.report "Time to read #{ITERATIONS} Event Snapshots" do
    ITERATIONS.times do
      EventStore::Client.new(rand(10) + 1, :device).snapshot
    end
  end
end

Benchmark.bmbm do |x|
  x.report "Time to read #{ITERATIONS} Event Streams" do
    ITERATIONS.times do
      EventStore::Client.new(rand(199) + 1, :device).event_stream
    end
  end
end

