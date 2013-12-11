require 'event_store/errors'

module EventStore
  class Client

    def initialize aggregate_id, aggregate_type
      @aggregate = Aggregate.new(aggregate_id, aggregate_type)
    end

    def append event_data
      EventAppender.new(@aggregate).append(event_data)
      yield(event_data) if block_given?
      nil
    end

    def event_stream
      @aggregate.events
    end

    def event_stream_from version, max=nil
      event_stream.starting_from_version(version).limit(max)
    end

    def peek
      @aggregate.last_event
    end

  end
end
