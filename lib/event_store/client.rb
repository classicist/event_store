require 'event_store/errors'

module EventStore
  class Client
    attr_reader :device_id

    def initialize device_id
      @device_id = device_id
    end

    def append(events, expected_sequence_number)
      # last_sequence_number =
      if last_sequence_number >= expected_sequence_number
        raise ConcurrencyError, "Expected sequence number #{expected_sequence_number} does not occur after last sequence number #{last_sequence_number}"
      else
        DB.transaction do
          events.each { |event| Event.create(event) }
          yield if block_given?
        end
      end
    end

    def event_stream
      @event_stream ||= Event.for_device(device_id)
    end

    def event_stream_from(sequence_number, max=nil)
      event_stream.from_sequence(sequence_number).limit(max)
    end

    def peek
      event_stream.order(:sequence_number).last
    end
  end
end
