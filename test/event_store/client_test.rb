require_relative '../minitest_helper'
require 'ostruct'

# run once setup
([1]*10 + [2]*10).shuffle.each do |device_id|
  event = EventStore::Event.new :device_id => device_id, :occurred_at => DateTime.now, :data => 234532.to_s(2)
  event.stub :validate, true do
    event.save
  end
end


describe EventStore::Client do
  before { @es_client = EventStore::Client }

  describe 'event streams' do
    it 'should be empty for devices without events' do
      stream = @es_client.new(100).event_stream
      assert stream.empty?
    end

    it 'should be for a single device' do
      stream = @es_client.new(1).event_stream
      assert stream.map(&:device_id).all?{ |device_id| device_id == '1' }, 'Fetched multiple device_ids in the event stream'
    end

    it 'should include all events for that device' do
      stream = @es_client.new(1).event_stream
      assert_equal 10, stream.count
    end
  end


  describe 'event streams from sequence' do
    subject { @es_client.new(1) }

    it 'should return events starting at the specified sequence number and above' do
      stream = subject.event_stream_from(2)
      assert stream.map(&:sequence_number).all?{ |sequence_number| sequence_number >= 2 }, 'Fetched sequence numbers below the specified sequence number'
    end

    it 'should respect the max, if specified' do
      stream = subject.event_stream_from(2, 5)
      assert_equal 5, stream.count
    end

    it 'should be empty for sequences above the current highest sequence number' do
      stream = subject.event_stream_from(43)
      assert stream.empty?
    end
  end

  describe '#peek' do
    subject { @es_client.new(1).peek }

    it 'should return one event' do
      assert_equal EventStore::Event, subject.class
    end

    it 'should return the last event in the event stream' do
      last_event = Sequel::Model.db.from(:event_store_events).where(device_id: 1).order(:sequence_number).last
      assert_equal last_event[:sequence_number], subject.sequence_number
    end
  end

  describe '#append' do
    before do
      @client = EventStore::Client.new(1)
      @event = @client.peek
      @new_event = OpenStruct.new(:header => OpenStruct.new(:device_id => "abc", :occurred_at => DateTime.now), :fully_qualified_name => "new", :data => 1.to_s(2))
    end

    describe "expected sequence number < last found sequence number" do
      describe 'type mismatch' do
        it 'should raise an error' do
          @event.update(:fully_qualified_name => "duplicate")
          @new_event.fully_qualified_name = "duplicate"
          assert_raises(EventStore::ConcurrencyError) { @client.append([@new_event], @event.sequence_number - 1) }
        end
      end

      describe 'no prior events of type' do
        it 'should succeed' do
          @event.update(:fully_qualified_name => "old")
          assert @client.append([@new_event], @event.sequence_number - 1)
        end
      end

      describe 'with prior events of same type' do
        it 'should raise an error' do
          @event.update(:fully_qualified_name => "new")
          assert_raises(EventStore::ConcurrencyError) { @client.append([@new_event], @event.sequence_number - 1) }
        end
      end

      it 'is run in a transaction' do
        bad_event = @new_event.dup
        bad_event.fully_qualified_name = nil
        starting_count = EventStore::Event.count
        assert_raises(Sequel::ValidationFailed) { @client.append([@new_event, bad_event], 1000) }
        assert_equal starting_count, EventStore::Event.count
      end
    end

    it 'yield to the block after event creation' do
      skip "needs clarification"
    end
  end

end
