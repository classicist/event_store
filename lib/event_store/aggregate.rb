module EventStore
  class Aggregate

    attr_reader :id, :type, :snapshot_table, :snapshot_version_table, :event_table

    def initialize(id, type = EventStore.table_name)
      @id = id
      @type = type
      @schema = EventStore.schema
      @event_table = EventStore.fully_qualified_table
      @snapshot_table = "#{@type}_snapshots_for_#{@id}"
      @snapshot_version_table = "#{@type}_snapshot_versions_for_#{@id}"
    end

    def events
      @events_query ||= EventStore.db.from(@event_table).where(:aggregate_id => @id.to_s).order(:version)
    end

    def snapshot
      events_hash = auto_rebuild_snapshot(read_raw_snapshot)
      snap = []
      events_hash.each_pair do |key, value|
        raw_event            = value.split(EventStore::SNAPSHOT_DELIMITER)
        fully_qualified_name = key
        version              = raw_event.first.to_i
        serialized_event     = raw_event[1]
        occurred_at          = Time.parse(raw_event.last)
        snap << SerializedEvent.new(fully_qualified_name, serialized_event, version, occurred_at)
      end
      snap.sort {|a,b| a.version <=> b.version}
    end

    def rebuild_snapshot!
      delete_snapshot!
      corrected_events = events.all.map{|e| e[:occurred_at] = TimeHacker.translate_occurred_at_from_local_to_gmt(e[:occurred_at]); e}
      EventAppender.new(self).store_snapshot(corrected_events)
    end

    def events_from(version_number, max = nil)
      events.limit(max).where{ version >= version_number.to_i }.all
    end

    def last_event
      snapshot.last
    end

    def version
      (EventStore.redis.hget(@snapshot_version_table, :current_version) || -1).to_i
    end

    def delete_snapshot!
      EventStore.redis.del [@snapshot_table, @snapshot_version_table]
    end

    def delete_events!
      events.delete
    end

  private
    def auto_rebuild_snapshot(events_hash)
      return events_hash unless events_hash.empty?
      event = events.select(:version).limit(1).all
      return events_hash if event.nil?
      rebuild_snapshot!
      events_hash = read_raw_snapshot
    end

    def read_raw_snapshot
      EventStore.redis.hgetall(@snapshot_table)
    end
  end
end