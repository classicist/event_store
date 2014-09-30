module EventStore
  class Snapshot

    def initialize aggregate
      @aggregate = aggregate
      @redis = EventStore.redis
      @snapshot_table = "#{aggregate.type}_snapshots_for_#{aggregate.id}"
      @snapshot_version_table = "#{aggregate.type}_snapshot_versions_for_#{aggregate.id}"
    end

    def last_event
      snapshot.last
    end

    def version
      (@redis.hget(@snapshot_version_table, :current_version) || -1).to_i
    end

    def snapshot
      events_hash = auto_rebuild_snapshot(read_raw_snapshot)
      snap = []
      events_hash.each_pair do |key, value|
        raw_event            = value.split(EventStore::SNAPSHOT_DELIMITER)
        fully_qualified_name = key
        version              = raw_event.first.to_i
        serialized_event     = EventStore.unescape_bytea(raw_event[1])
        occurred_at          = Time.parse(raw_event.last)
        snap << SerializedEvent.new(fully_qualified_name, serialized_event, version, occurred_at)
      end
      snap.sort {|a,b| a.version <=> b.version}
    end

    def rebuild_snapshot!
      delete_snapshot!
      corrected_events = @aggregate.events.all.map{|e| e[:occurred_at] = TimeHacker.translate_occurred_at_from_local_to_gmt(e[:occurred_at]); e}
      @snapshot.store_snapshot(corrected_events)
    end

    def delete_snapshot!
      EventStore.redis.del [@snapshot_table, @snapshot_version_table]
    end

    def store_snapshot(prepared_events)
      valid_snapshot_events = []
      valid_snapshot_versions = []

      prepared_events.each do |event_hash|
        if event_hash[:version].to_i > current_version_numbers[event_hash[:fully_qualified_name]].to_i
          valid_snapshot_events   += snapshot_event(event_hash)
          valid_snapshot_versions += snapshot_version(event_hash)
        end
      end

      unless valid_snapshot_versions.empty?
        valid_snapshot_versions += [:current_version, valid_snapshot_versions.last.to_i]

        @redis.multi do
          @redis.hmset(@snapshot_version_table, valid_snapshot_versions)
          @redis.hmset(@snapshot_table, valid_snapshot_events)
        end
      end
    end


  private

    def auto_rebuild_snapshot(events_hash)
      return events_hash unless events_hash.empty? #got it? return it

      event = @aggregate.events.select(:version).limit(1).all
      return events_hash if event.nil? #return nil if no events in the ES

      # so there are events in the ES but there is no redis snapshot
      rebuild_snapshot!
      events_hash = read_raw_snapshot
    end

    def read_raw_snapshot
      @redis.hgetall(@snapshot_table)
    end

    def snapshot_event(event)
      [
        event[:fully_qualified_name],
        [ event[:version].to_s,
          event[:serialized_event],
          event[:occurred_at].to_s
        ].join(EventStore::SNAPSHOT_DELIMITER)
      ]
    end

    def snapshot_version(event)
      [
        event[:fully_qualified_name],
        event[:version]
      ]
    end

    def current_version_numbers
      current_versions = @redis.hgetall(@snapshot_version_table)
      current_versions.default = -1
      current_versions
    end

  end
end
