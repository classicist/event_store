require_relative '../spec_helper'
require 'ostruct'

describe EventStore::Client do
  let(:es_client) { EventStore::Client }

  before do
    client_1 = es_client.new('1', :device)
    client_2 = es_client.new('2', :device)

    events_by_aggregate_id  = {'1' => [], '2' => []}
    ([1]*10 + [2]*10).shuffle.each do |aggregate_id|
      events_by_aggregate_id[aggregate_id.to_s] << EventStore::Event.new(aggregate_id.to_s, DateTime.now, 'event_name', 234532.to_s(2))
    end
    client_1.append events_by_aggregate_id['1']
    client_2.append events_by_aggregate_id['2']
  end

  describe 'raw event streams' do
    it 'should be empty for aggregates without events' do
      stream = es_client.new(100, :device).raw_event_stream
      expect(stream.empty?).to be_true
    end

    it 'should be for a single aggregate' do
      stream = es_client.new(1, :device).raw_event_stream
      stream.each { |event| event[:aggregate_id].should == '1' }
    end

    it 'should include all events for that aggregate' do
      stream = es_client.new(1, :device).raw_event_stream
      expect(stream.count).to eq(10)
    end
  end

  describe 'event streams' do
    it 'should be empty for aggregates without events' do
      stream = es_client.new(100, :device).raw_event_stream
      expect(stream.empty?).to be_true
    end

    it 'should be generated for a single aggregate' do
      raw_stream = es_client.new(1, :device).raw_event_stream
      stream = es_client.new(1, :device).event_stream
      stream.map(&:fully_qualified_name).should == raw_stream.inject([]){|m, event| m << event[:fully_qualified_name]; m}
    end

    it 'should include all events for that aggregate' do
      stream = es_client.new(1, :device).event_stream
      expect(stream.count).to eq(10)
    end
  end


  describe 'event streams from version' do
    subject { es_client.new(1, :device) }

    it 'should respect the max, if specified' do
      stream = subject.event_stream_from(2, 5)
      expect(stream.count).to eq(5)
    end

    it 'should be empty for version above the current highest version number' do
      stream = subject.event_stream_from(123456)
      expect(stream).to be_empty
    end
  end

  describe '#peek' do
    subject { es_client.new(1, :device).peek }

    it 'should return the last event in the event stream' do
      last_event = EventStore.db.from(:device_events).where(aggregate_id: '1').order(:version).last
      expect(subject).to eq(EventStore::SerializedEvent.new(last_event[:fully_qualified_name], last_event[:serialized_event]))
    end
  end

  describe '#append' do
    before do
      @client = EventStore::Client.new('1', :device)
      @event = @client.peek
      @duplicate_event = EventStore::Event.new('1', DateTime.now, 'duplicate', 12.to_s(2))
      @old_event = EventStore::Event.new('1', DateTime.now - 200, "old", 1000.to_s(2))
      @new_event = EventStore::Event.new('1', DateTime.now - 100, "new", 1001.to_s(2))
      @really_new_event = EventStore::Event.new('1', DateTime.now, "really_new", 1002.to_s(2))
    end

    describe "expected version number < last version" do
      describe 'no prior events of type' do
        before do
          @client.append([@old_event])
        end

        it 'should succeed' do
          expect(@client.append([@new_event])).to_not raise_error
        end

        it 'should succeed with multiple events of the same type' do
          expect(@client.append([@new_event, @new_event])).to_not raise_error
        end

        context 'snapshot' do
          it "#append should write-through cache the event in a snapshot" do
            @client.snapshot.should == [EventStore::SerializedEvent.new(@old_event.fully_qualified_name, @old_event.serialized_event), EventStore::SerializedEvent.new('event_name', 234532.to_s(2))]
          end
        end
      end

      describe 'with prior events of same type' do
        it 'should raise an error' do
          @client.append([@duplicate_event])
          reset_expected_version_in(@client)
          expect { @client.append([@duplicate_event]) }.to raise_error(EventStore::ConcurrencyError)
        end

        it 'should not raise an error' do
          @client.append([@duplicate_event])
          expect { @client.append([@duplicate_event]) }.to_not raise_error
        end

        it "#append should write-through cache the event in a snapshot without duplicating events" do
          @client.append([@old_event, @old_event, @old_event])
          @client.snapshot.should == [EventStore::SerializedEvent.new(@old_event.fully_qualified_name, @old_event.serialized_event), EventStore::SerializedEvent.new('event_name', 234532.to_s(2))]
        end
      end
    end

    describe 'transactional' do
      before do
        @bad_event = @new_event.dup
        @bad_event.fully_qualified_name = nil
      end

      it 'should revert all append events if one fails' do
        starting_count = EventStore.db.from(:device_events).count
        expect { @client.append([@new_event, @bad_event]) }.to raise_error(EventStore::AttributeMissingError)
        expect(EventStore.db.from(:device_events).count).to eq(starting_count)
      end

      it 'does not yield to the block if it fails' do
        x = 0
        expect { @client.append([@bad_event]) { x += 1 } }.to raise_error(EventStore::AttributeMissingError)
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

    describe 'snapshot' do
      before do
        @client = es_client.new('10', :device)
        @client.snapshot.length.should == 0
        @client.append %w{ e1 e2 e3 e1 e2 e4 e5 e2 e5 e4}.map {|fqn| EventStore::Event.new('10', DateTime.now, fqn, 234532.to_s(2)) }
      end

      it "finds the most recent records for each type" do
        expected_snapshot = %w{ e1 e2 e3 e4 e5 }.map {|fqn| EventStore::SerializedEvent.new(fqn, 234532.to_s(2)) }
        @client.event_stream.length.should == 10
        @client.snapshot.length.should == 5
        expect(@client.snapshot).to match_array(expected_snapshot)
      end

      it "increments the version number of the snapshot when an event is appended" do
        @client.raw_snapshot[:version].should == @client.raw_event_stream.last[:version]
      end
    end


    def reset_expected_version_in(client)
      client.define_singleton_method(:event_appender) do
        @event_appender ||= EventStore::EventAppender.new(@aggregate)
        @event_appender.define_singleton_method(:expected_version) {@expected_version = 0}
        @event_appender
      end
    end
  end
end
