module EventStore
  class EventStream
    include Enumerable

    attr_reader :event_table, :checkpoint_event

    def initialize aggregate
      @aggregate = aggregate
      @id = @aggregate.id
      @checkpoint_event = aggregate.checkpoint_event
      @event_table_alias = "events"
      @event_table = "#{EventStore.schema}__#{EventStore.table_name}".to_sym
      @aliased_event_table = "#{event_table}___#{@event_table_alias}".to_sym
      @names_table = EventStore.fully_qualified_names_table
    end

    def append(raw_events, logger)
      prepared_events = raw_events.map do |raw_event|
        event = prepare_event(raw_event)
        ensure_all_attributes_have_values!(event)
        event
      end

      prepared_events.each do |event|
        event_hash = event.dup.reject! { |k,v| k == :fully_qualified_name }
        event_table = insert_table(Time.now)

        begin
          id = event_table.insert(event_hash)
        rescue Sequel::NotNullConstraintViolation
          fully_qualified_names.insert(fully_qualified_name: event[:fully_qualified_name])
          id = event_table.insert(event_hash)
        end

        logger.debug("EventStream#append, setting id #{id} for #{event_hash.inspect}")

        event[:id] = id
      end

      yield(prepared_events) if block_given?
    end

    def insert_table(occurred_at)
      EventStore.db.from(insert_table_name(occurred_at))
    end

    def insert_table_name(date)
      EventStore.insert_table_name(date)
    end

    def fully_qualified_names
      @fully_qualified_name_query ||= EventStore.db.from(@names_table)
    end

    def events
      @events_query ||=
        begin
          query = EventStore.db.from(@aliased_event_table).where(:aggregate_id => @id.to_s)
          query = query.join(@names_table, id: :fully_qualified_name_id) if EventStore.use_names_table?
          query = query.order("#{@event_table_alias}__id".to_sym).select_all(:events)
          query = query.select_append(:fully_qualified_name) if EventStore.use_names_table?
          query
        end
    end

    def snapshot_events
      last_checkpoint = last_event_before(Time.now.utc, [checkpoint_event]).first if checkpoint_event

      if last_checkpoint
        events.where{ events__id >= last_checkpoint[:id].to_i }
      else
        events
      end
    end

    def events_from(event_id, max = nil)
      # note: this depends on the events table being aliased to "events" above.
      events.limit(max).where{events__id >= event_id.to_i }.all.map do |event|
        event[:serialized_event] = EventStore.unescape_bytea(event[:serialized_event])
        event
      end
    end

    def last_event_before(start_time, fully_qualified_names = [])
      timestampz = start_time.strftime("%Y-%m-%d %H:%M:%S%z")

      rows = fully_qualified_names.inject([]) { |memo, name|
        memo + events.where(fully_qualified_name: name).where{ occurred_at < timestampz }
                 .reverse_order(:occurred_at, :id).limit(1).all
      }.sort_by { |r| r[:occurred_at] }

      rows.map {|r| r[:serialized_event] = EventStore.unescape_bytea(r[:serialized_event]); r}
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
      EventStore.db.from(@event_table).where(:aggregate_id => @id.to_s).delete
    end

  private

    def prepare_event(raw_event)
      raise ArgumentError.new("Cannot Append a Nil Event") unless raw_event
      { :aggregate_id            => raw_event.aggregate_id,
        :occurred_at             => Time.parse(raw_event.occurred_at.to_s).utc, #to_s truncates microseconds, which breaks Time equality
        :serialized_event        => EventStore.escape_bytea(raw_event.serialized_event),
        :fully_qualified_name    => raw_event.fully_qualified_name,
        :sub_key                 => raw_event.sub_key
      }.tap { |event_info|
        if EventStore.use_names_table?
          name_subquery = EventStore.db.from(@names_table).where(fully_qualified_name: raw_event.fully_qualified_name).select(:id)
          event_info[:fully_qualified_name_id] = name_subquery
        end
      }
    end

    def ensure_all_attributes_have_values!(event_hash)
      [:aggregate_id, :fully_qualified_name, :occurred_at, :serialized_event].each do |attribute_name|
        if event_hash[attribute_name].to_s.strip.empty?
          raise AttributeMissingError, "value required for #{attribute_name}"
        end
      end
    end
  end
end
