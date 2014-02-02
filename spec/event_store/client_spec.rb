require_relative '../spec_helper'
require 'ostruct'

describe EventStore::Client do
  let(:es_client) { EventStore::Client }

  before do
    client_1 = es_client.new('1', :device)
    client_2 = es_client.new('2', :device)

    events_by_aggregate_id  = {'1' => [], '2' => []}
    @event_time = DateTime.new(2001,2,3,4,5,6)
    ([1]*10 + [2]*10).shuffle.each_with_index do |aggregate_id, version|
      events_by_aggregate_id[aggregate_id.to_s] << EventStore::Event.new(aggregate_id.to_s, @event_time, 'event_name', 234532.to_s(2), version)
    end
    client_1.append events_by_aggregate_id['1']
    client_2.append events_by_aggregate_id['2']
  end

  describe '#raw_event_stream' do
    it "should be an array of hashes that represent database records, not EventStore::SerializedEvent objects" do
      raw_stream = es_client.new(1, :device).raw_event_stream
      raw_stream.class.should == Array
      raw_event = raw_stream.first
      raw_event.class.should == Hash
      raw_event.keys.should == [:id, :version, :aggregate_id, :fully_qualified_name, :occurred_at, :serialized_event]
    end

    it 'should be empty for aggregates without events' do
      stream = es_client.new(100, :device).raw_event_stream
      expect(stream.empty?).to be_true
    end

    it 'should only have events for a single aggregate' do
      stream = es_client.new(1, :device).raw_event_stream
      stream.each { |event| event[:aggregate_id].should == '1' }
    end

    it 'should have all events for that aggregate' do
      stream = es_client.new(1, :device).raw_event_stream
      expect(stream.count).to eq(10)
    end
  end

  describe '#event_stream' do
    it "should be an array of EventStore::SerializedEvent objects" do
      stream = es_client.new(1, :device).event_stream
      stream.class.should == Array
      event = stream.first
      event.class.should == EventStore::SerializedEvent
    end

    it 'should be empty for aggregates without events' do
      stream = es_client.new(100, :device).raw_event_stream
      expect(stream.empty?).to be_true
    end

    it 'should only have events for a single aggregate' do
      raw_stream = es_client.new(1, :device).raw_event_stream
      stream = es_client.new(1, :device).event_stream
      stream.map(&:fully_qualified_name).should == raw_stream.inject([]){|m, event| m << event[:fully_qualified_name]; m}
    end

    it 'should have all events for that aggregate' do
      stream = es_client.new(1, :device).event_stream
      expect(stream.count).to eq(10)
    end
  end


  describe '#raw_event_streams_from_version' do
    subject { es_client.new(1, :device) }

    it 'should return all the raw events in the stream starting from a certain version' do
      minimum_event_version = 2
      raw_stream = subject.raw_event_stream_from(minimum_event_version)
      event_versions = raw_stream.inject([]){|m, event| m << event[:version]; m}
      event_versions.min.should >= minimum_event_version
    end

    it 'should return no more than the maximum number of events specified above the ' do
      max_number_of_events  = 5
      minimum_event_version = 2
      raw_stream = subject.raw_event_stream_from(minimum_event_version, max_number_of_events)
      expect(raw_stream.count).to eq(max_number_of_events)
    end

    it 'should be empty for version above the current highest version number' do
      raw_stream = subject.raw_event_stream_from(subject.version + 1)
      expect(raw_stream).to be_empty
    end
  end

  describe 'event_stream_from_version' do
    subject { es_client.new(1, :device) }

    it 'should return all the raw events in the stream starting from a certain version' do
      minimum_event_version = 2
      raw_stream = subject.raw_event_stream_from(minimum_event_version)
      event_versions = raw_stream.inject([]){|m, event| m << event[:version]; m}
      event_versions.min.should >= minimum_event_version
    end

    it 'should return no more than the maximum number of events specified above the ' do
      max_number_of_events  = 5
      minimum_event_version = 2
      raw_stream = subject.raw_event_stream_from(minimum_event_version, max_number_of_events)
      expect(raw_stream.count).to eq(max_number_of_events)
    end

    it 'should be empty for version above the current highest version number' do
      raw_stream = subject.raw_event_stream_from(subject.version + 1)
      raw_stream.should == []
    end
  end

  describe '#peek' do
    let(:client) {es_client.new(1, :device)}
    subject { client.peek }

    it 'should return the last event in the event stream' do
      last_event = EventStore.db.from(client.event_table).where(aggregate_id: '1').order(:version).last
      subject.should == EventStore::SerializedEvent.new(last_event[:fully_qualified_name], last_event[:serialized_event], last_event[:version], @event_time)
    end
  end

  describe '#append' do
    before do
      @client = EventStore::Client.new('1', :device)
      @event = @client.peek
      version = @client.version
      @old_event = EventStore::Event.new('1', (@event_time - 200), "old", 1000.to_s(2), version += 1)
      @new_event = EventStore::Event.new('1', (@event_time - 100), "new", 1001.to_s(2), version += 1)
      @really_new_event = EventStore::Event.new('1', (@event_time), "really_new", 1002.to_s(2), version += 1)
      @duplicate_event  = EventStore::Event.new('1', (@event_time + 100), 'duplicate', 12.to_s(2), version += 1)
    end

    describe "when expected version number is greater than the last version" do
      describe 'and there are no prior events of type' do
        before do
          @client.append([@old_event])
        end

        it 'should append a single event of a new type without raising an error' do
          initial_count = @client.count
          events = [@new_event]
          @client.append(events)
          @client.count.should == initial_count + events.length
        end

        it 'should append multiple events of a new type without raising and error' do
          initial_count = @client.count
          events = [@new_event, @new_event]
          @client.append(events)
          @client.count.should == initial_count + events.length
        end

        it "should increment the version number by the number of events added" do
          events = [@new_event, @really_new_event]
          initial_version = @client.version
          @client.append(events)
          @client.version.should == (initial_version + events.length)
        end

        it "should set the snapshot version number to match that of the last event in the aggregate's event stream" do
          events = [@new_event, @really_new_event]
          initial_stream_version = @client.raw_event_stream.last[:version]
          @client.snapshot.last.version.should == initial_stream_version
          @client.append(events)
          updated_stream_version = @client.raw_event_stream.last[:version]
          @client.snapshot.last.version.should == updated_stream_version
        end

        it "should write-through-cache the event in a snapshot without duplicating events" do
          @client.destroy!
          @client.append([@old_event, @new_event, @really_new_event])
          @client.snapshot.should == @client.event_stream
        end
      end

      describe 'with prior events of same type' do
        it 'should raise a ConcurrencyError if the the event version is less than current version' do
          @client.append([@duplicate_event])
          reset_current_version_for(@client)
          expect { @client.append([@duplicate_event]) }.to raise_error(EventStore::ConcurrencyError)
        end

        it 'should not raise an error when two events of the same type are appended' do
          @client.append([@duplicate_event])
          @duplicate_event[:version] += 1
          @client.append([@duplicate_event]) #will fail automatically if it throws an error, no need for assertions (which now print warning for some reason)
        end

        it "should write-through-cache the event in a snapshot without duplicating events" do
          @client.destroy!
          @client.append([@old_event, @new_event, @new_event])
          expected =  []
          expected << @client.event_stream.first
          expected << @client.event_stream.last
          @client.snapshot.should == expected
        end

        it "should increment the version number by the number of unique events added" do
          events = [@old_event, @old_event, @old_event]
          initial_version = @client.version
          @client.append(events)
          @client.version.should == (initial_version + events.uniq.length)
        end

        it "should set the snapshot version number to match that of the last event in the aggregate's event stream" do
          events = [@old_event, @old_event]
          initial_stream_version = @client.raw_event_stream.last[:version]
          @client.snapshot.last.version.should == initial_stream_version
          @client.append(events)
          updated_stream_version = @client.raw_event_stream.last[:version]
          @client.snapshot.last.version.should == updated_stream_version
        end
      end
    end

    describe 'transactional' do
      before do
        @bad_event = @new_event.dup
        @bad_event.fully_qualified_name = nil
      end

      it 'should revert all append events if one fails' do
        starting_count = @client.count
        expect { @client.append([@new_event, @bad_event]) }.to raise_error(EventStore::AttributeMissingError)
        expect(@client.count).to eq(starting_count)
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
        version = @client.version
        @client.append %w{ e1 e2 e3 e1 e2 e4 e5 e2 e5 e4}.map {|fqn| EventStore::Event.new('10', Time.now.utc, fqn, 234532.to_s(2), version += 1)}
      end
require 'set'
      it "finds the most recent records for each type" do
        version = @client.version
        expected_snapshot = %w{ e1 e2 e3 e4 e5 }.map {|fqn| EventStore::SerializedEvent.new(fqn, 234532.to_s(2), version +=1 ) }
        @client.event_stream.length.should == 10
        actual_snapshot = @client.snapshot
        actual_snapshot.length.should == 5
        actual_snapshot.map(&:fully_qualified_name).should == ["e3", "e1", "e2", "e5", "e4"] #sorted by version no
        actual_snapshot.map(&:serialized_event).should == expected_snapshot.map(&:serialized_event)
        most_recent_events_of_each_type = {}
        @client.event_stream.each do |e|
          if most_recent_events_of_each_type[e.fully_qualified_name].nil? || most_recent_events_of_each_type[e.fully_qualified_name].version < e.version
            most_recent_events_of_each_type[e.fully_qualified_name] = e
          end
        end
        actual_snapshot.map(&:version).should == most_recent_events_of_each_type.values.map(&:version).sort
      end

      it "increments the version number of the snapshot when an event is appended" do
        @client.snapshot.last.version.should == @client.raw_event_stream.last[:version]
      end
    end


    def reset_current_version_for(client)
      aggregate = client.instance_variable_get("@aggregate")
      EventStore.redis.hset(aggregate.snapshot_version_table, :current_version, 1000)
    end
  end
end
