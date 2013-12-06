module EventStore
  class EventAppender

    def initialize device, expected_sequence_number
      @device = device
      @expected_sequence_number = expected_sequence_number
    end

    def append raw_events
      Event.db.transaction do
        prepared_events = raw_events.map do |raw_event|
          event = prepare_event(raw_event)
          raise concurrency_error if has_concurrency_issue?(event)
          event
        end

        # All concurrency issues need to be checked before persisting any of the events
        # Otherwise, the newly appended events may raise erroneous concurrency errors
        prepared_events.each(&:save)
      end
    end

    private

    def concurrency_issue_possible?
      @potential_concurrency_issue ||= @expected_sequence_number < @device.last_event.sequence_number
    end

    def has_concurrency_issue? event
      if concurrency_issue_possible?
        last_event_of_type = @device.last_event_of_type(event.fully_qualified_name)
        last_event_of_type && @expected_sequence_number < last_event_of_type.sequence_number
      else
        false
      end
    end

    def prepare_event raw_event
      Event.new do |e|
        e.device_id            = raw_event.header.device_id
        e.occurred_at          = raw_event.header.occurred_at
        e.data                 = raw_event.to_s
        e.fully_qualified_name = raw_event.fully_qualified_name
      end
    end

    def concurrency_error
      ConcurrencyError.new("Expected sequence number #{@expected_sequence_number} does not occur after last sequence number")
    end

  end
end