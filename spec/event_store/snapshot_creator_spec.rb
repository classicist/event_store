require_relative '../spec_helper'

describe EventStore::SnapshotCreator do
  it "can find the latest snapshot" do
    aggregate = EventStore::Aggregate.new(123, :device)
    snapshot1 = EventStore::Snapshot.create :aggregate_id => aggregate.id, :aggregate_type => aggregate.type, :event_ids => [1,2,3]
    snapshot2 = EventStore::Snapshot.create :aggregate_id => aggregate.id, :aggregate_type => aggregate.type, :event_ids => [1,2,3]
    expect(EventStore::Snapshot.last_snapshot(aggregate)).to eq(snapshot2)
  end

  context "counting past events" do
    xit "without a pre-existing snapshot" do
      aggregate = EventStore::Aggregate.new(123, :device)
      expect(EventStore::SnapshotCreator.new(aggregate).events_since_last_snapshot).to eq(0)
    end
  end
end