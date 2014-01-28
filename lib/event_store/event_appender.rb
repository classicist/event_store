module EventStore
  class EventAppender

    def initialize aggregate
      @aggregate = aggregate
    end

    def append raw_events
      EventStore.db.transaction do
        set_current_version

        prepared_events = raw_events.map do |raw_event|
          event = prepare_event(raw_event)
          validate! event
          raise concurrency_error(event) if has_concurrency_issue?(event)
          event
        end

        # All concurrency issues need to be checked before persisting any of the events
        # Otherwise, the newly appended events may raise erroneous concurrency errors
        result = @aggregate.events.multi_insert(prepared_events)
        store_snapshot(prepared_events) if result
        result
      end
    end

    private

    def store_snapshot(prepared_events)
      r = EventStore.redis
      current_version_numbers = r.hgetall(@aggregate.snapshot_version_table)
      valid_snapshot_events = []
      valid_snapshot_versions = []
      prepared_events.each do |event|
        if event[:version].to_i > current_version_numbers[event[:fully_qualified_name]].to_i
          valid_snapshot_events   << event[:fully_qualified_name]
          valid_snapshot_events   << (event[:version].to_s + EventStore::SNAPSHOT_DELIMITER + event[:serialized_event])
          valid_snapshot_versions << event[:fully_qualified_name]
          valid_snapshot_versions << event[:version]
        end
      end
      unless valid_snapshot_versions.empty?
        last_version            = valid_snapshot_versions.last
        valid_snapshot_versions << :current_version
        valid_snapshot_versions << last_version
        r.multi do
          r.hmset(@aggregate.snapshot_version_table, valid_snapshot_versions)
          r.hmset(@aggregate.snapshot_table, valid_snapshot_events)
        end
      end
   end

    def has_concurrency_issue? event
      event[:version] <= current_version
    end

    def prepare_event raw_event
      { :version              => raw_event.version,
        :aggregate_id         => raw_event.aggregate_id,
        :occurred_at          => raw_event.occurred_at,
        :serialized_event     => raw_event.serialized_event,
        :fully_qualified_name => raw_event.fully_qualified_name }
    end

    def concurrency_error event
      ConcurrencyError.new("The version of the event being added (version #{event[:version]}) is <= the current version (version #{current_version})")
    end

    private
    def current_version
      @current_version ||= @aggregate.version
    end
    alias :set_current_version :current_version

    def validate! event_hash
      [:aggregate_id, :fully_qualified_name, :occurred_at, :serialized_event, :version].each do |attribute_name|
        if event_hash[attribute_name].to_s.strip.empty?
          raise AttributeMissingError, "value required for #{attribute_name}"
        end
      end
    end

  end
end