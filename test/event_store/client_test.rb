require 'minitest/autorun'
require 'minitest/pride'
require 'sequel'
require 'pry'

DB = Sequel.sqlite

DB.create_table!(:event_store_events) do
  primary_key :id
  String   :device_id
  String   :name
  Integer  :sequence_number
  DateTime :occurred_at
  bytea    :data
end

require 'event_store'

describe EventStore::Client do
  before do
    @event_store = EventStore::Client.new
  end

  describe 'event streams' do
    before do
      [1, 2].each do |device_id|
        20.times do
          event = EventStore::Event.new :device_id => device_id, :sequence_number => rand(9)
          event.stub :validate, true do
            event.save
          end
        end
      end
    end

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
      binding.pry
      assert_equal DB.from(:event_store_events).where(:device_id => '1').count, stream.count
    end
  end

end
