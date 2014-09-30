require 'spec_helper'
require 'securerandom'

AGGREGATE_ID_ONE   = SecureRandom.uuid
AGGREGATE_ID_TWO   = SecureRandom.uuid
AGGREGATE_ID_THREE = SecureRandom.uuid

module EventStore
  describe 'snapshot' do
    let(:es_client) { EventStore::Client }

    before do
      @client = es_client.new(AGGREGATE_ID_THREE, :device)
      expect(@client.snapshot.length).to eq(0)
      @version = @client.version
      @client.append events_for(AGGREGATE_ID_THREE)
    end

    it "finds the most recent records for each type" do
      @version = @client.version
      expected_snapshot = serialized_events
      actual_snapshot = @client.snapshot

      expect(@client.event_stream.length).to eq(10)
      expect(actual_snapshot.length).to eq(5)
      expect(actual_snapshot.map(&:fully_qualified_name)).to eq(["e3", "e1", "e2", "e5", "e4"]) #sorted by version no
      expect(actual_snapshot.map(&:serialized_event)).to eq(expected_snapshot.map(&:serialized_event))

      most_recent_events_of_each_type = {}
      @client.event_stream.each do |e|
        if most_recent_events_of_each_type[e.fully_qualified_name].nil? || most_recent_events_of_each_type[e.fully_qualified_name].version < e.version
          most_recent_events_of_each_type[e.fully_qualified_name] = e
        end
      end

      expect(actual_snapshot.map(&:version)).to eq(most_recent_events_of_each_type.values.map(&:version).sort)
    end

    it "increments the version number of the snapshot when an event is appended" do
      expect(@client.snapshot.last.version).to eq(@client.raw_event_stream.last[:version])
    end

    def events_for(device_id)
      version = @version
      %w{ e1 e2 e3 e1 e2 e4 e5 e2 e5 e4}.map do |fqn|
        EventStore::Event.new(device_id,
                              Time.now.utc,
                              fqn,
                              serialized_binary_event_data,
                              version += 1)
      end
    end

    def serialized_events
      version = @version
      %w{ e1 e2 e3 e4 e5 }.map {|fqn| EventStore::SerializedEvent.new(fqn, serialized_binary_event_data, version +=1 ) }
    end

    def serialized_binary_event_data
      @event_data ||= File.open(File.expand_path("../serialized_binary_event_data.txt", __FILE__), 'rb') {|f| f.read}
      @event_data
    end
  end
end
