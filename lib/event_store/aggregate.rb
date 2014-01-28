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

    def snapshot
      events_hash = EventStore.redis.hgetall(@snapshot_table)
      snap = []
      events_hash.each_pair do |key, value|
        fully_qualified_name = key
        raw_event = value.split(EventStore::SNAPSHOT_DELIMITER)
        version   = raw_event.first
        serialized_event = raw_event.last
        snap << SerializedEvent.new(fully_qualified_name, serialized_event, version.to_i)
      end
      snap.sort {|a,b| a.version <=> b.version}
    end

    def events_from(version_number, max = nil)
      events.limit(max).where{ version >= version_number.to_i }.all
    end

    def last_event
      snapshot.last
    end

    def version
      EventStore.redis.hget(@snapshot_version_table, :current_version).to_i
    end

    def delete_snapshot!
      EventStore.redis.del [@snapshot_table, @snapshot_version_table]
    end

    def delete_events!
      events.delete
    end
  end
end