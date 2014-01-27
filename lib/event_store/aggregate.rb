module EventStore
  class Aggregate

    attr_reader :id, :type, :snapshot_table, :snapshot_version_table

    def initialize id, type
      @id = id
      @type = type
      @event_table = "#{@type}_events"
      @snapshot_table = "#{@type}_snapshots_for_#{@id}"
      @snapshot_version_table = "#{@type}_snapshot_versions_for_#{@id}"
    end

    def events
      @events_query ||= EventStore.db.from(@event_table).where(:aggregate_id => @id.to_s).order(:version)
    end

    def events_from(version_number, max = nil)
      events.limit(max).where{ version >= version_number.to_i }.all
    end

    def snapshot(min = 0, max = -1)
      events = EventStore.redis.zrange(@snapshot_table, min, max, with_scores: true) || []
      events.map do |event_with_score|
        raw_event = event_with_score.first.split(EventStore::SNAPSHOT_DELIMITER)
        version   = event_with_score.last
        fully_qualified_name = raw_event.first
        serialized_event     = raw_event.last
        SerializedEvent.new(fully_qualified_name, serialized_event, version.to_i)
      end
    end

    def last_event
      snapshot(-1, -1).last
    end

    def version
      last_event.version
    end

    def delete_snapshot!
      EventStore.redis.del [@snapshot_table, @snapshot_version_table]
    end

    def delete_events!
      events.delete
    end
  end
end