module EventStore
  class EventAppender

    def initialize device, expected_sequence_number
      @device = device
      @expected_sequence_number = expected_sequence_number
    end

    def append raw_events
      Event.db.transaction do
        raw_events.map { |raw_event| prepare_event(raw_event) }.each(&:save)
      end
    end

    private

    def has_potential_concurrency_issue?
      @potential_concurrency_issue ||= @expected_sequence_number < @device.last_event.sequence_number
    end

    def prepare_event raw_event
      event = Event.new do |e|
        e.device_id            = raw_event.header.device_id
        e.occurred_at          = raw_event.header.occurred_at
        e.data                 = raw_event.to_s
        e.fully_qualified_name = raw_event.fully_qualified_name
      end

      if has_potential_concurrency_issue? && event.has_concurrency_issue?(@expected_sequence_number)
        raise ConcurrencyError, "Expected sequence number #{@expected_sequence_number} does not occur after last sequence number"
      end

      event
    end

  end
end