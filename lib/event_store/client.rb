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

    def snapshot
      translate_snapshot(raw_snapshot[:snapshot] || {})
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
      @aggregate.snapshot || {}
    end

    def raw_event_stream
      @aggregate.events.all
    end

    def raw_event_stream_from version_number, max=nil
      @aggregate.events_from(version_number, max)
    end

    def version
      v = raw_snapshot[:version]
      v.nil? ? 0 : v
    end

    def count
      event_stream.length
    end

    def destroy!
      @aggregate.events.delete
      @aggregate.snapshot.delete
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

    def translate_snapshot(snapshot_hash)
      events = []
      snapshot_hash.each_pair {|fully_qualified_name, serialized_event| events << translate_event(fully_qualified_name: fully_qualified_name, serialized_event: serialized_event)}
      events
    end
  end
end
