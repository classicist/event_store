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
      translate_events @aggregate.events
    end

    def event_stream_from version_number, max=nil
      translate_events @aggregate.events.where{ version >= version_number.to_i }.limit(max)
    end

    def peek
      translate_event @aggregate.events.last
    end

    def current_state
      translate_events @aggregate.current_state
    end

    private

    def translate_events(event_hashs)
      event_hashs.map { |eh| translate_event(eh) }
    end

    def translate_event(event_hash)
      Event.new event_hash[:aggregate_id], event_hash[:occurred_at], event_hash[:data], event_hash[:fully_qualified_name]
    end
  end
end
