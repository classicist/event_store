module EventStore
  class Aggregate

    attr_reader :id

    def initialize id, type
      @id = id
      @type = type
      @event_table = "#{@type}_events"
      @snapshot_table = "#{@type}_snapshots"
    end

    def events
      @events_query ||= EventStore.db.from(@event_table).where(:aggregate_id => @id.to_s).order(:version)
    end

    def snapshot
      snapshot_query.first
    end

    def events_from(version_number, max = nil)
      events.limit(max).where{ version >= version_number.to_i }
    end

    def last_event
      events.limit(1).last
    end

    def last_event_of_type(fully_qualified_name)
      snapshot_query.where("snapshot ? '#{fully_qualified_name}'").first
    end

    def snapshot_query
      @snapshot_query ||=  EventStore.db.from(@snapshot_table).where(:aggregate_id => @id.to_s).limit(1)
    end
  end
end