require 'spec_helper'
require 'mock_redis'

module EventStore
  describe Snapshot do
    let(:redis)          { EventStore.redis }
    let(:aggregate_type) { "awesome" }
    let(:aggregate_id)   { "superman" }
    let(:events)         { [] }
    let(:aggregate)      { double("Aggregate", type: aggregate_type, id: aggregate_id, events: double(all: events)) }

    subject(:snapshot)   { EventStore::Snapshot.new(aggregate) }

    it "has a version table for the snapshot" do
      expect(snapshot.snapshot_version_table).to eq "#{aggregate_type}_snapshot_versions_for_#{aggregate_id}"
    end

    context "with events in the snapshot table" do
      let(:first_event) {
        { version: 1,
          fully_qualified_name: "fqn",
          sub_key: "sub",
          serialized_event: EventStore.escape_bytea("cheerios"),
          occurred_at: Time.at( (Time.now - 3600).to_i )
        }
      }
      let(:last_event) {
        { version: 2,
          fully_qualified_name: "fqn2",
          sub_key: "sub2",
          serialized_event: EventStore.escape_bytea("cheerios2"),
          occurred_at: Time.at( (Time.now - 1800).to_i )
        }
      }
      let(:events) { [ first_event, last_event ] }

      before(:each) { snapshot.store_snapshot(events) }

      describe "#last_event" do
        let(:events) { [ last_event, first_event ] }

        it "returns the event with the highest version" do
          expect(snapshot.last_event.fully_qualified_name).to eq(last_event[:fully_qualified_name])
        end
      end

      describe "#version" do
        it "is the highest version of the last inserted event in the snapshot" do
          expect(snapshot.version).to eq(last_event[:version])
        end
      end

      describe "#version_for" do
        let(:subkey) { first_event[:sub_key] }
        let(:fqn)    { first_event[:fully_qualified_name] }

        it "returns the version number for the last event of specific fqn" do
          expect(snapshot.version_for(fqn, subkey)).to eq(first_event[:version])
        end
      end

      describe "#rebuild_snapshot!" do
        it "deletes the existing snapshot" do
          expect(redis).to receive(:del).with([snapshot.snapshot_table , snapshot.snapshot_version_table])
          snapshot.rebuild_snapshot!
        end

        it "stores a a new snapshot from the aggregate's events" do
          snapshot.rebuild_snapshot!
          expect(snapshot.count).to eq(2)
          # TODO: remove #snapshot in favor of Enumerable
          names = snapshot.map(&:fully_qualified_name)
          expect(names).to eq(events.map { |e| e[:fully_qualified_name] })
        end
      end

      # TODO: remove this in favor of #each and include Enumerable
      describe "events" do
        let(:serialized_attrs) { [ :fully_qualified_name,
                                   :serialized_event,
                                   :version,
                                   :occurred_at ] }

        it "contains SerializedEvents" do
          snapshot.each { |e| expect(e).to be_a(SerializedEvent) }
        end

        it "corresponds to the events used to build the snapshot" do
          (serialized_attrs - [ :serialized_event ]).each { |attr|
            expect(snapshot.first.send(attr)).to eq(first_event[attr])
            expect(snapshot.last_event.send(attr)).to eq(last_event[attr])
          }
        end

        it "unescapes the serialized events" do
          expected_event = EventStore.unescape_bytea(first_event[:serialized_event])
          expect(snapshot.first.serialized_event).to eq(expected_event)
        end
      end

      describe "#exists?" do
        it "does exist" do
          expect(snapshot.exists?).to eq(true)
        end

        context "without a snapshot" do
          before(:each) { snapshot.delete_snapshot! }

          it "does not exist" do
            expect(snapshot.exists?).to eq(false)
          end
        end
      end
    end
  end
end
