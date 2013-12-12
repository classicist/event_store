module EventStore
  class SnapshotCreator
    def initialize aggregate
      @aggregate = aggregate
    end

    def events_since_last_snapshot
      self.class.last_snapshot(@aggregate)
      @aggregate
    end

    def needs_new_snapshot?
      false
    end

    def self.last_snapshot(aggregate)
      Snapshot.last_snapshot(aggregate)
    end
  end
end