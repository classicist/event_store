module EventStore
  class Client

    def initialize aggregate_id, aggregate_type
      @aggregate = Aggregate.new(aggregate_id, aggregate_type)
    end

    def id
      @aggregate.id
    end

    def type
      @aggregate.type
    end

    def append event_data
      event_appender.append(event_data)
      yield(event_data) if block_given?
      nil
    end

    def snapshot
      raw_snapshot
    end

    def event_stream
      translate_events raw_event_stream
    end

    def event_stream_from version_number, max=nil
      translate_events @aggregate.events_from(version_number, max)
    end

    def peek
      translate_event @aggregate.last_event
    end

    def raw_snapshot
      @aggregate.snapshot || []
    end

    def raw_event_stream
      @aggregate.events.all
    end

    def raw_event_stream_from version_number, max=nil
      @aggregate.events_from(version_number, max)
    end

    def version
      @aggregate.version
    end

    def count
      event_stream.length
    end

    def destroy!
      @aggregate.delete_events!
      @aggregate.delete_snapshot!
    end

    private

    def event_appender
      EventAppender.new(@aggregate)
    end

    def translate_events(event_hashs)
      event_hashs.map { |eh| translate_event(eh) }
    end

    def translate_event(event_hash)
      SerializedEvent.new event_hash[:fully_qualified_name], event_hash[:serialized_event], event_hash[:version]
    end
  end
end
