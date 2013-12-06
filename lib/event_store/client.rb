require 'event_store/errors'

module EventStore
  class Client

    attr_reader :device_id

    def initialize device_id
      @device = Device.new(device_id)
    end

    def append event_data, expected_sequence_number
      appender = EventAppender.new(@device, expected_sequence_number).append(event_data)
      yield if block_given?
      true
    end

    def event_stream
      @device.events
    end

    def event_stream_from sequence_number, max=nil
      event_stream.starting_from_sequence_number(sequence_number).limit(max)
    end

    def peek
      @device.last_event
    end

  end
end
