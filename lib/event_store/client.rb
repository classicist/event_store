module EventStore
  class Client

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

    def event_stream(device_id)
      Event.for_device(device_id)
    end

    def event_stream_from(device_id, sequence_number, max=nil)
      event_stream(device_id).from_sequence(sequence_number).limit(max)
    end

    def peek(device_id)
      event_stream(device_id).last
    end

    class ConcurrencyError < Exception; end

  end
end
