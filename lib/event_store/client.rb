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

    def event_stream_from version_number, max=nil
      event_stream.where{ version >= version_number.to_i }.limit(max)
    end

    def peek
      event_stream.last
    end

    def current_state
      @aggregate.current_state
    end

  end
end
