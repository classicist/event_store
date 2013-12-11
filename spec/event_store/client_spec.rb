require_relative '../spec_helper'
require 'ostruct'

# one time setup
event_class = EventStore::Aggregate.new(1, :device).event_class
([1]*10 + [2]*10).shuffle.each do |aggregate_id|
  event_class.create :aggregate_id => aggregate_id, :occurred_at => DateTime.now, :data => 234532.to_s(2), :fully_qualified_name => 'event_name'
end

# Forgive me
set_expected_version = ->(version_number) {
  EventStore::EventAppender.class_eval(
    %Q(def expected_version; #{version_number}; end)
  )
}

describe EventStore::Client do
  let(:es_client) { EventStore::Client }

  describe 'event streams' do
    it 'should be empty for aggregates without events' do
      stream = es_client.new(100, :device).event_stream
      expect(stream.empty?).to be_true
    end

    it 'should be for a single aggregate' do
      stream = es_client.new(1, :device).event_stream
      expect(stream.map(&:aggregate_id).all?{ |aggregate_id| aggregate_id == '1' }).to be_true
    end

    it 'should include all events for that aggregate' do
      stream = es_client.new(1, :device).event_stream
      expect(stream.count).to eq(10)
    end
  end


  describe 'event streams from version' do
    subject { es_client.new(1, :device) }

    it 'should return events starting at the specified version and above' do
      stream = subject.event_stream_from(2)
      expect(stream.map(&:version).all?{ |version| version >= 2 }).to be_true
    end

    it 'should respect the max, if specified' do
      stream = subject.event_stream_from(2, 5)
      expect(stream.count).to eq(5)
    end

    it 'should be empty for version above the current highest version number' do
      stream = subject.event_stream_from(43)
      expect(stream).to be_empty
    end
  end

  describe '#peek' do
    subject { es_client.new(1, :device).peek }

    it 'should return the last event in the event stream' do
      last_event = Sequel::Model.db.from(:device_events).where(aggregate_id: 1).order(:version).last
      expect(subject.version).to eq(last_event[:version])
    end
  end

  describe '#append' do
    before do
      @client = EventStore::Client.new(1, :device)
      @event = @client.peek
      @new_event = OpenStruct.new(:header => OpenStruct.new(:aggregate_id => '1', :occurred_at => DateTime.now), :fully_qualified_name => "new", :data => 1.to_s(2))
      set_expected_version.call(0)
    end

    describe "expected version number < last version" do
      describe 'type mismatch' do
        it 'should raise an error' do
          @event.update(:fully_qualified_name => "duplicate")
          @new_event.fully_qualified_name = "duplicate"

          expect { @client.append([@new_event]) }.to raise_error(EventStore::ConcurrencyError)
        end
      end

      describe 'no prior events of type' do
        before do
          @event.update(:fully_qualified_name => "old")
          set_expected_version.call(0)
        end

        it 'should succeed' do
          expect(@client.append([@new_event])).to be_nil
        end

        it 'should succeed with multiple events of the same type' do
          expect(@client.append([@new_event, @new_event])).to be_nil
        end
      end

      describe 'with prior events of same type' do
        it 'should raise an error' do
          @event.update(:fully_qualified_name => "new")
          expect { @client.append([@new_event]) }.to raise_error(EventStore::ConcurrencyError)
        end
      end
    end

    describe 'transactional' do
      before do
        @bad_event = @new_event.dup
        @bad_event.fully_qualified_name = nil
        set_expected_version.call(1000)
      end

      it 'should revert all append events if one fails' do
        starting_count = EventStore::DeviceEvent.count
        expect { @client.append([@new_event, @bad_event]) }.to raise_error(Sequel::ValidationFailed)
        expect(EventStore::DeviceEvent.count).to eq(starting_count)
      end

      it 'does not yield to the block if it fails' do
        x = 0
        expect { @client.append([@bad_event]) { x += 1 } }.to raise_error(Sequel::ValidationFailed)
        expect(x).to eq(0)
      end

      it 'yield to the block after event creation' do
        x = 0
        @client.append([]) { x += 1 }
        expect(x).to eq(1)
      end

      it 'should pass the raw event_data to the block' do
        @client.append([@new_event]) do |raw_event_data|
          expect(raw_event_data).to eq([@new_event])
        end
      end
    end

  end

end
