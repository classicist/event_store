module EventStore
  class EventAppender

    def initialize device, expected_sequence_number
      @device = device
      @expected_sequence_number = expected_sequence_number
    end

    def append raw_events
      Event.db.transaction do
        prepared_events = prepare_events raw_events
        check_for_concurrency_issues(prepared_events) if concurrency_issue_possible?
        commit prepared_events
      end
    end

    private

    def concurrency_issue_possible?
      @potential_concurrency_issue ||= @expected_sequence_number < @device.last_event.sequence_number
    end

    def check_for_concurrency_issues events
      events.each do |event|
        if has_concurrency_issue? event
          raise ConcurrencyError, "Expected sequence number #{@expected_sequence_number} does not occur after last sequence number"
        end
      end
    end

    def has_concurrency_issue? event
      last_event_of_type = @device.last_event_of_type(event.fully_qualified_name)
      last_event_of_type && @expected_sequence_number < last_event_of_type.sequence_number
    end

    def prepare_events raw_events
      raw_events.map do |raw_event|
        Event.new do |e|
          e.device_id            = raw_event.header.device_id
          e.occurred_at          = raw_event.header.occurred_at
          e.data                 = raw_event.to_s
          e.fully_qualified_name = raw_event.fully_qualified_name
        end
      end
    end

    def commit events
      events.each(&:save)
    end

  end
end