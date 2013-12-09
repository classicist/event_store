require 'event_store/errors'

module EventStore
  class Client

    attr_reader :aggregate_id

    def initialize aggregate_id
      @aggregate = Aggregate.new(aggregate_id)
    end

    def append event_data, expected_sequence_number
      appender = EventAppender.new(@aggregate, expected_sequence_number).append(event_data)
      yield if block_given?
      true
    end

    def event_stream
      @aggregate.events
    end

    def event_stream_from sequence_number, max=nil
      event_stream.starting_from_sequence_number(sequence_number).limit(max)
    end

    def peek
      @aggregate.last_event
    end

  end
end
