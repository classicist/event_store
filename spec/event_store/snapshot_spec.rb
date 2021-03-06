require 'spec_helper'
module EventStore
  describe "Snapshots" do
    let(:aggregate_id)  {'100A' }
    let(:new_aggregate) { Aggregate.new(aggregate_id) }
    let(:client)        { Client.new(aggregate_id) }
    let(:appender)      { EventAppender.new(new_aggregate) }
    let(:events)        { Array.new }

    before do
      @event_time = Time.parse("2001-01-01 00:00:00 UTC")
      (0...10).to_a.each_with_index do |version|
        events << EventStore::Event.new(aggregate_id, @event_time, 'event_name', "#{234532.to_s(2)}_foo}", version)
      end
    end

    it "should build an empty snapshot for a new client" do
      new_aggregate.snapshot.should == []
      new_aggregate.version.should == -1
      EventStore.redis.hget(new_aggregate.snapshot_version_table, :current_version).should == nil
    end

    it "should rebuild a snapshot after it is deleted" do
      appender.append(events)
      snapshot = new_aggregate.snapshot
      version  = new_aggregate.version
      new_aggregate.delete_snapshot!
      new_aggregate.rebuild_snapshot!
      new_aggregate.snapshot.should == snapshot
    end

    it "a client should rebuild a snapshot" do
      Aggregate.any_instance.should_receive(:delete_snapshot!)
      Aggregate.any_instance.should_receive(:rebuild_snapshot!)
      client.rebuild_snapshot!
    end

    it "should rebuild the snapshot if events exist, but the snapshot is empty" do
      appender.append(events)
      snapshot = new_aggregate.snapshot
      new_aggregate.delete_snapshot!
      new_aggregate.snapshot.should == snapshot
    end
  end
end