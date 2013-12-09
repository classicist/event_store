require_relative '../spec_helper'
require 'ostruct'

# one time setup
([1]*10 + [2]*10).shuffle.each do |device_id|
  EventStore::Event.create :device_id => device_id, :occurred_at => DateTime.now, :data => 234532.to_s(2), :fully_qualified_name => 'event_name'
end

describe EventStore::Client do
  let(:es_client) { EventStore::Client }

  describe 'event streams' do
    it 'should be empty for devices without events' do
      stream = es_client.new(100).event_stream
      expect(stream.empty?).to be_true
    end

    it 'should be for a single device' do
      stream = es_client.new(1).event_stream
      expect(stream.map(&:device_id).all?{ |device_id| device_id == '1' }).to be_true
    end

    it 'should include all events for that device' do
      stream = es_client.new(1).event_stream
      expect(stream.count).to eq(10)
    end
  end


  describe 'event streams from sequence' do
    subject { es_client.new(1) }

    it 'should return events starting at the specified sequence number and above' do
      stream = subject.event_stream_from(2)
      expect(stream.map(&:sequence_number).all?{ |sequence_number| sequence_number >= 2 }).to be_true
    end

    it 'should respect the max, if specified' do
      stream = subject.event_stream_from(2, 5)
      expect(stream.count).to eq(5)
    end

    it 'should be empty for sequences above the current highest sequence number' do
      stream = subject.event_stream_from(43)
      expect(stream).to be_empty
    end
  end

  describe '#peek' do
    subject { es_client.new(1).peek }

    it 'should return one event' do
      expect(subject.class).to eq(EventStore::Event)
    end

    it 'should return the last event in the event stream' do
      last_event = Sequel::Model.db.from(:event_store_events).where(device_id: 1).order(:sequence_number).last
      expect(subject.sequence_number).to eq(last_event[:sequence_number])
    end
  end

  describe '#append' do
    before do
      @client = EventStore::Client.new(1)
      @event = @client.peek
      @new_event = OpenStruct.new(:header => OpenStruct.new(:device_id => '1', :occurred_at => DateTime.now), :fully_qualified_name => "new", :data => 1.to_s(2))
    end

    describe "expected sequence number < last found sequence number" do
      describe 'type mismatch' do
        it 'should raise an error' do
          @event.update(:fully_qualified_name => "duplicate")
          @new_event.fully_qualified_name = "duplicate"
          expect { @client.append([@new_event], @event.sequence_number - 1) }.to raise_error(EventStore::ConcurrencyError)
        end
      end

      describe 'no prior events of type' do
        before do
          @event.update(:fully_qualified_name => "old")
        end

        it 'should succeed' do
          expect(@client.append([@new_event], @event.sequence_number - 1)).to be_true
        end

        it 'should succeed with multiple events of the same type' do
          expect(@client.append([@new_event, @new_event], @event.sequence_number - 1)).to be_true
        end
      end

      describe 'with prior events of same type' do
        it 'should raise an error' do
          @event.update(:fully_qualified_name => "new")
          expect { @client.append([@new_event], @event.sequence_number - 1) }.to raise_error(EventStore::ConcurrencyError)
        end
      end
    end

    describe 'transactional' do
      before do
        @bad_event = @new_event.dup
        @bad_event.fully_qualified_name = nil
      end

      it 'should revert all append events if one fails' do
        starting_count = EventStore::Event.count
        expect { @client.append([@new_event, @bad_event], 1000) }.to raise_error(Sequel::ValidationFailed)
        expect(EventStore::Event.count).to eq(starting_count)
      end

      it 'does not yield to the block if it fails' do
        x = 0
        expect { @client.append([@bad_event], 100) { x += 1 } }.to raise_error(Sequel::ValidationFailed)
        expect(x).to eq(0)
      end

      it 'yield to the block after event creation' do
        x = 0
        @client.append([], 100) { x += 1 }
        expect(x).to eq(1)
      end
    end

  end

end
