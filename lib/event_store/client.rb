module EventStore
  class Client

    def initialize aggregate_id, aggregate_type
      @aggregate = Aggregate.new(aggregate_id, aggregate_type)
    end

    def append event_data
      event_appender.append(event_data)
      yield(event_data) if block_given?
      nil
    end

    def event_stream
      translate_events @aggregate.events
    end

    def raw_event_stream
      @aggregate.events.all
    end

    def event_stream_from version_number, max=nil
      translate_events @aggregate.events_from(version_number, max)
    end

    def peek
      translate_event @aggregate.last_event
    end

    def current_state
      @aggregate.snapshot
    end

    def raw_snapshot
      @aggregate.snapshot_query.first
    end

    def aggregate_id
      @aggregate.id
    end

    def current_version(type)
      @aggregate.last_event_of_type(type)[:version]
    end

    private

    def event_appender
      EventAppender.new(@aggregate)
    end

    def translate_events(event_hashs)
      event_hashs.map { |eh| translate_event(eh) }
    end

    def translate_event(event_hash)
      SerializedEvent.new event_hash[:fully_qualified_name], event_hash[:serialized_event]
    end

    def translate_raw_events(event_hashs)
      event_hashs.map { |eh| Event.new eh[:aggregate_id], eh[:occurred_at], eh[:fully_qualified_name], eh[:serialized_event] }
    end
  end
end
