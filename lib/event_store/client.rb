require 'event_store/errors'

module EventStore
  class Client

    attr_reader :device_id

    def initialize device_id
      @device_id = device_id
    end

    def append events, expected_sequence_number, &block
      if expected_sequence_number < peek.sequence_number
        check_for_concurrency_issues events, expected_sequence_number
      end
      create_events events, &block
    end

    def event_stream
      @event_stream ||= Event.for_device(device_id)
    end

    def event_stream_from sequence_number, max=nil
      event_stream.starting_from_sequence_number(sequence_number).limit(max)
    end

    def peek
      event_stream.last
    end

    private

    def check_for_concurrency_issues events, expected_sequence_number
      events.each do |event|
        last_event = last_event_of_type(event.fully_qualified_name)
        if last_event && expected_sequence_number < last_event.sequence_number
          raise ConcurrencyError, "Expected sequence number #{expected_sequence_number} does not occur after last sequence number"
        end
      end
    end

    def last_event_of_type type
      event_stream.where(:fully_qualified_name => type).last
    end

    def create_events events
      Event.db.transaction do
        events.each { |event| Event.create(EventSerializer.new(event).serialize) }
      end
      yield if block_given?
      true
    end

  end
end
