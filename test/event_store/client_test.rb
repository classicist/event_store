require_relative '../minitest_helper'
require 'event_store'

EventStore.configure do |es|
  es.db = test_db
end

# run once setup
[1, 2].each do |device_id|
  20.times do
    event = EventStore::Event.new :device_id => device_id, :sequence_number => rand(9)
    event.stub :validate, true do
      event.save
    end
  end
end

describe EventStore::Client do
  before do
    @event_store = EventStore::Client.new
  end

  describe 'event streams' do
    it 'should be empty for devices without events' do
      stream = @event_store.event_stream(100)
      assert_equal 0, stream.count
    end

    it 'should be for a single device' do
      stream = @event_store.event_stream(1)
      assert stream.map(&:device_id).all?{ |device_id| device_id == '1' }, 'Fetched multiple device_ids in the event stream'
    end

    it 'should include all events for that device' do
      stream = @event_store.event_stream(1)
      assert_equal 20, stream.count
    end
  end

end
