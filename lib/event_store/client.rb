module EventStore
  class Client

    def append(events, expected_sequence_number)
      # last_sequence_number =
      if last_sequence_number >= expected_sequence_number
        raise ConcurrencyError, "Expected sequence number #{expected_sequence_number} does not occur after last sequence number #{last_sequence_number}"
      else
        DB.transaction do
          events.each { |event| EventStoreEvent.create(event) }
          yield if block_given?
        end
      end
    end

    def event_stream(device_id)
      Device.new(device_id).event_stream
    end

    def event_stream_from(device_id, sequence_number, max=0)
      stream = Device.new(device_id).sequence(sequence_number)
      max == 0 ? stream : stream.limit(max)
    end

    def peek(device_id)
      event_stream(device_id).last
    end

    class ConcurrencyError < Exception; end

  end
end
