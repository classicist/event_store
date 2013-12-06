module EventStore
  class EventAppender

    def initialize device, expected_sequence_number
      @device = device
      @expected_sequence_number = expected_sequence_number
    end

    def append raw_events
      if @expected_sequence_number < @device.events.last.sequence_number
        check_for_concurrency_issues raw_events
      end
      create_events raw_events
    end

    private

    def check_for_concurrency_issues raw_events
      raw_events.each do |raw_event|
        last_event = @device.events.of_type(raw_event.fully_qualified_name).last
        if last_event && @expected_sequence_number < last_event.sequence_number
          raise ConcurrencyError, "Expected sequence number #{@expected_sequence_number} does not occur after last sequence number"
        end
      end
    end

    def create_events raw_events
      Event.db.transaction do
        raw_events.each { |raw_event| Event.create(translate_raw_event_to_attributes(raw_event)) }
      end
    end

    def translate_raw_event_to_attributes raw_event
      {
        :device_id            => raw_event.header.device_id,
        :occurred_at          => raw_event.header.occurred_at,
        :data                 => raw_event.to_s,
        :fully_qualified_name => raw_event.fully_qualified_name
      }
    end

  end
end