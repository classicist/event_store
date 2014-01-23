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
      translate_events @aggregate.events
    end

    def raw_event_stream
      translate_raw_events @aggregate.events
    end

    def event_stream_from version_number, max=nil
      translate_events @aggregate.events_from(version_number, max)
    end

    def peek
      translate_event @aggregate.last_event
    end

    def current_state
      translate_events @aggregate.last_event_of_each_type
    end

    def raw_snapshot
      @aggregate.snapshot
    end

    private

    def translate_events(event_hashs)
      event_hashs.map { |eh| translate_event(eh) }
    end

    def translate_event(event_hash)
      SerializedEvent.new event_hash[:fully_qualified_name], event_hash[:serialized_event]
    end

    def translate_raw_events(event_hashs)
      event_hashs.map { |eh| Event.new eh[:aggregate_id], eh[:occurred_at], eh[:serialized_event], eh[:fully_qualified_name] }
    end
  end
end
