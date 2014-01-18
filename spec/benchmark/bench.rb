require 'rspec'
require 'event_store'
require 'benchmark'

EventStore.connect :adapter => :postgres, :database => 'event_store_performance', :host => 'localhost'

ITERATIONS = 100

Benchmark.bmbm do |x|
  x.report "Time to read #{ITERATIONS} Event Streams" do
    ITERATIONS.times do
      EventStore::Client.new(rand(300) + 1, :device).event_stream
    end
  end
end
