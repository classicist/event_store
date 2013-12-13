module EventStore
  class SnapshotCreator
    def initialize aggregate
      @aggregate = aggregate
    end

    def create_snapshot!
      events = @aggregate.current_state
      Snapshot.create(:aggregate_id => @aggregate.id, :aggregate_type => @aggregate.type, :event_ids => events.map(&:version))
    end

    def needs_new_snapshot?
      events_since_last_snapshot >= 100
    end

    private

   def events_since_last_snapshot
     if last_snap = Snapshot.latest_for_aggregate(@aggregate)
       @aggregate.events.where("version >= ?", last_snap.event_ids.max).count
     else
       @aggregate.events.count
     end
   end
  end
end