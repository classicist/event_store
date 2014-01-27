module EventStore
  class EventAppender

    def initialize aggregate
      @aggregate = aggregate
    end

    def append raw_events
      EventStore.db.transaction do
        prepared_snapshot = {}
        @number_of_new_events = raw_events.length
        set_expected_version
        current_version = version_of_last_event

        prepared_events = raw_events.map do |raw_event|
          current_version += 1
          event = prepare_event(raw_event, current_version)
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
      prepared_events.each do |event|
        r = EventStore.redis
        old_version_number = r.hget(@aggregate.snapshot_version_table, event[:fully_qualified_name]) || -1
        r.multi do
          if event[:version].to_i > old_version_number.to_i
            r.zremrangebyscore(@aggregate.snapshot_table, old_version_number.to_s, old_version_number.to_s)
            r.hset(@aggregate.snapshot_version_table, event[:fully_qualified_name], event[:version].to_s)
            r.zadd(@aggregate.snapshot_table, event[:version].to_s, event[:fully_qualified_name] + EventStore::SNAPSHOT_DELIMITER + event[:serialized_event])
          end
        end
      end
    end

    def has_concurrency_issue? event
      expected_version < event[:version]
    end

    def prepare_event raw_event, version
      { :version              => version,
        :aggregate_id         => raw_event.aggregate_id,
        :occurred_at          => raw_event.occurred_at,
        :serialized_event     => raw_event.serialized_event,
        :fully_qualified_name => raw_event.fully_qualified_name }
    end

    def concurrency_error event
      ConcurrencyError.new("Expected version #{expected_version} does not occur after last version #{event[:version]}")
    end

    private

    def version_of_last_event
      last_event = @aggregate.last_event
      last_event ? @aggregate.last_event[:version] : 0
    end

    def expected_version
      @expected_version ||= version_of_last_event + @number_of_new_events
    end
    alias :set_expected_version :expected_version

    def validate! event_hash
      [:aggregate_id, :fully_qualified_name, :occurred_at, :serialized_event, :version].each do |attribute_name|
        if event_hash[attribute_name].to_s.strip.empty?
          raise AttributeMissingError, "value required for #{attribute_name}"
        end
      end
    end

  end
end