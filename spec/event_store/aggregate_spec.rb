require_relative '../spec_helper'

# one time setup
event_class = EventStore::Aggregate.new(12, :device).event_class
(1..10).each do |i|
  event_class.create :aggregate_id => 12, :occurred_at => DateTime.now, :data => 234532.to_s(2), :fully_qualified_name => "e_#{i}"
end

describe EventStore::Aggregate do
  it "should search for event types" do
    aggregate = EventStore::Aggregate.new(12, :device)
    event_ids = (1..10).to_a
    snapshot = EventStore::Snapshot.new(:aggregate_id => aggregate.id, :aggregate_type => aggregate.type, :event_ids => event_ids)
    expect(aggregate.all_event_types(snapshot)).to match_array((1..10).map {|i| "e_#{i}" })
  end

  it "should find the event types since a certain id" do
    aggregate = EventStore::Aggregate.new(12, :device)
    ar = (1..10).map {|i| "e_#{i}" }
    expect(aggregate.event_types_since(5)).to match_array(ar[5,5])
  end

end