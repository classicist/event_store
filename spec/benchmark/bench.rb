require 'event_store'
require 'benchmark'

EventStore.configure do
  adapter  :postgres
  database ENV['BM-DATABASE']
  username ENV['BM-USERNAME']
  password ENV['BM-PASSWORD']
  host     ENV['BM-HOST']
  post     ENV['BM-PORT']
end

ITERATIONS = 100_000

Benchmark.bmbm do |x|
  x.report 'Read time' do
    ITERS.times do
      EventStore::Client.new(1, :device)
    end
  end
end
