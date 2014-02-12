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

    def event_table
      @aggregate.event_table
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
      occurred_at =  translate_occurred_at_from_local_to_gmt(event_hash[:occurred_at])
      SerializedEvent.new event_hash[:fully_qualified_name], event_hash[:serialized_event], event_hash[:version], occurred_at
    end

    #Hack around various DB adapters that hydrate dates from the db into the local ruby timezone
    def translate_occurred_at_from_local_to_gmt(occurred_at)
      if occurred_at.class == Time
        #expecting "2001-02-03 01:26:40 -0700"
        Time.parse(occurred_at.to_s.gsub(/\s[+-]\d+$/, ' UTC'))
      elsif occurred_at.class == DateTime
        #expecting "2001-02-03T01:26:40+00:00"
        Time.parse(occurred_at.iso8601.gsub('T', ' ').gsub(/[+-]\d{2}\:\d{2}/, ' UTC'))
      end
    end
  end
end
