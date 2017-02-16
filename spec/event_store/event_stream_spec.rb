require "spec_helper"

module EventStore
  describe EventStream do
    let(:aggregate_id) { SecureRandom.uuid }
    let(:checkpoint_events) {
      %w[ checkpoint_event_1 checkpoint_event_2 ]
    }
    let(:aggregate) {
      Aggregate.new(
        aggregate_id,
        EventStore.table_name,
        checkpoint_events
      )
    }

    let(:event_time) { Time.parse("2001-01-01 00:00:00 UTC") }

    let(:events) {
      [EventStore::Event.new(aggregate_id, (event_time - 2000).utc, "old_event", "zone", "#{1000.to_s(2)}_foo"),
       EventStore::Event.new(aggregate_id, (event_time - 1000).utc, "checkpoint_event_2", "zone", "#{1001.to_s(2)}_foo"),
       EventStore::Event.new(aggregate_id, (event_time + 100).utc,  "after_checkpoint_1", "zone", "#{1002.to_s(2)}_foo"),
       EventStore::Event.new(aggregate_id, (event_time).utc,        "after_checkpoint_2", "zone", "#{12.to_s(2)}_foo")]
    }

    subject(:event_stream) { EventStream.new aggregate }

    let(:logger) { Logger.new("/dev/null") }

    before(:each) do
      event_stream.append events, logger
    end

    describe "#snapshot_events" do
      it "returns events since the last of one of multiple checkpoint events" do
        snapshot_events = event_stream.snapshot_events

        expect(snapshot_events.count).to eql(3)

        expect(
          snapshot_events.find { |event| event[:fully_qualified_name] == 'checkpoint_event_2' }
        ).not_to be_nil

        expect(
          snapshot_events.find { |event| event[:fully_qualified_name] == 'after_checkpoint_1' }
        ).not_to be_nil

        expect(
          snapshot_events.find { |event| event[:fully_qualified_name] == 'after_checkpoint_2' }
        ).not_to be_nil
      end

      it "raises an exception if multiple event types are returned" do
        event = EventStore::Event.new(aggregate_id,
                                      (event_time - 1000).utc,
                                      "checkpoint_event_1",
                                      "zone",
                                      "#{1001.to_s(2)}_foo")

        event_stream.append [event], logger

        expect { event_stream.snapshot_events }.to raise_error do |error|
          expect(error).to be_a(RuntimeError)
          expect(error.message).to eql("unexpected multiple checkpoint event types")
        end
      end
    end
  end
end
