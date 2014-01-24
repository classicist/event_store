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
      @aggregate_events_query ||= EventStore.db.from(@event_table).where(:aggregate_id => @id.to_s).order(:version)
    end

    def events_from(version_number, max = nil)
      events.limit(max).where{ version >= version_number.to_i }
    end

    def last_event
      events.limit(1).last
    end

    def current_version
      latest_snapshot = snapshot_query.order(:version).last
      latest_snapshot ? latest_snapshot[:version] : -1
    end

    def last_event_of_type(fully_qualified_name)
      snapshot_query.where("snapshot ? '#{fully_qualified_name}'").first
    end

    def snapshot_query
      @snapshot_query ||=  EventStore.db.from(@snapshot_table).where(:aggregate_id => @id.to_s).limit(1)
    end

    def snapshot
      @snapshot = snapshot_query.first
      return [] unless @snapshot
      snapshot = @snapshot[:snapshot]
      cached_events = []
      snapshot.each_pair do |event_name, serialized_event|
        cached_events << EventStore::SerializedEvent.new(event_name, serialized_event)
      end
      cached_events
    end
  end
end