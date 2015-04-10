module EventStore
  class EventStream
    include Enumerable

    attr_reader :event_table

    def initialize aggregate
      @aggregate = aggregate
      @id = @aggregate.id
      @event_table = EventStore.fully_qualified_table
    end

    def append(raw_events)
      EventStore.db.transaction do
        next_version = last_version + 1

        prepared_events = raw_events.map do |raw_event|
          event = prepare_event(raw_event, next_version)
          next_version += 1
          ensure_all_attributes_have_values!(event)
          event
        end

        events.multi_insert(prepared_events)

        yield(prepared_events) if block_given?
      end
    end

    def events
      @events_query ||= EventStore.db.from(@event_table).where(:aggregate_id => @id.to_s).order(:version)
    end

    def events_from(version_number, max = nil)
      events.limit(max).where{ version >= version_number.to_i }.all.map do |event|
        event[:serialized_event] = EventStore.unescape_bytea(event[:serialized_event])
        event
      end
    end

    def last_event_before(start_time, fully_qualified_names = [])
      timestampz = start_time.strftime("%Y-%m-%d %H:%M:%S%z")
      names = fully_qualified_names.map { |n| "'#{n}'" }.join(',')
      last_event_before_query = <<-EOSQL
      SELECT * FROM
          (SELECT *, LAST_VALUE(occurred_at)
             OVER(PARTITION BY fully_qualified_name ORDER BY occurred_at
                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last
          FROM #{@event_table}
          WHERE aggregate_id = '#{@id}'
            AND fully_qualified_name IN (#{names})
            AND occurred_at < '#{timestampz}') AS subquery
      WHERE occurred_at = last
      ORDER BY occurred_at
      EOSQL

      query = EventStore.db[last_event_before_query]
      query.all.map {|e| e[:serialized_event] = EventStore.unescape_bytea(e[:serialized_event]); e}
    end

    def event_stream_between(start_time, end_time, fully_qualified_names = [])
      query = events.where(occurred_at: start_time..end_time)
      query = query.where(fully_qualified_name: fully_qualified_names) if fully_qualified_names && fully_qualified_names.any?
      query.all.map {|e| e[:serialized_event] = EventStore.unescape_bytea(e[:serialized_event]); e}
    end

    def last
      to_a.last
    end

    def empty?
      events.empty?
    end

    def each
      events.all.each do |e|
        e[:serialized_event] = EventStore.unescape_bytea(e[:serialized_event])
        yield e
      end
    end

    def delete_events!
      events.delete
    end

  private

    def prepare_event(raw_event, version_number)
      raise ArgumentError.new("Cannot Append a Nil Event") unless raw_event
      { :version              => version_number,
        :aggregate_id         => raw_event.aggregate_id,
        :occurred_at          => Time.parse(raw_event.occurred_at.to_s).utc, #to_s truncates microseconds, which brake Time equality
        :serialized_event     => EventStore.escape_bytea(raw_event.serialized_event),
        :fully_qualified_name => raw_event.fully_qualified_name,
        :sub_key              => raw_event.sub_key
      }
    end

    def ensure_all_attributes_have_values!(event_hash)
      [:aggregate_id, :fully_qualified_name, :occurred_at, :serialized_event, :version].each do |attribute_name|
        if event_hash[attribute_name].to_s.strip.empty?
          raise AttributeMissingError, "value required for #{attribute_name}"
        end
      end
    end

    def last_version
      last = events.select(:version).last
      last && last[:version] || -1
    end

  end
end
