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

        prepared_events = raw_events.map do |raw_event|
          event = prepare_event(raw_event)
          validate! event
          prepared_snapshot[raw_event.fully_qualified_name] = raw_event.serialized_event
          raise concurrency_error if has_concurrency_issue?(event)
          event
        end

        # All concurrency issues need to be checked before persisting any of the events
        # Otherwise, the newly appended events may raise erroneous concurrency errors
        result = @aggregate.events.multi_insert(prepared_events)
        store_snapshot(prepared_snapshot) if result
        result
      end
    end

    private

    def store_snapshot(prepared_snapshot)
      snapshot_row = @aggregate.snapshot
      if snapshot_row
        updated_snapshot = snapshot_row[:snapshot].merge(prepared_snapshot.hstore)
        @aggregate.snapshot_query.update(snapshot: updated_snapshot, version: version_of_last_event)
      else
        @aggregate.snapshot_query.insert(aggregate_id: @aggregate.id, version: version_of_last_event, snapshot: prepared_snapshot.hstore)
      end
    end

    def has_concurrency_issue? event
      if concurrency_issue_possible?
        expected_version < version_of_last_event_of_type(event)
      else
        false
      end
    end

    def concurrency_issue_possible?
      @potential_concurrency_issue ||= expected_version < version_of_last_event
    end

    def prepare_event raw_event
      { :aggregate_id         => raw_event.aggregate_id,
        :occurred_at          => raw_event.occurred_at,
        :serialized_event     => raw_event.serialized_event,
        :fully_qualified_name => raw_event.fully_qualified_name }
    end

    def concurrency_error
      ConcurrencyError.new("Expected version #{expected_version} does not occur after last version")
    end

    private

    def version_of_last_event
      last_event = @aggregate.last_event
      last_event ? @aggregate.last_event[:version] : 0
    end

    def version_of_last_event_of_type(event)
      last_event_of_type = @aggregate.last_event_of_type(event[:fully_qualified_name])
      last_event_of_type ? last_event_of_type[:version] : 0
    end

    def expected_version
      @expected_version ||= version_of_last_event + @number_of_new_events
    end
    alias :set_expected_version :expected_version

    def validate! event_hash
      [:aggregate_id, :fully_qualified_name, :occurred_at, :serialized_event].each do |attribute_name|
        if event_hash[attribute_name].to_s.strip.empty?
          raise AttributeMissingError, "value required for #{attribute_name}"
        end
      end
    end

  end
end