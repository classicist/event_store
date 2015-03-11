module EventStore
  class Client
    extend Forwardable

    def_delegators :aggregate, :delete_snapshot!, :snapshot_version_table, :version_for

    def self.count
      Aggregate.count
    end

    def self.ids(offset, limit)
      Aggregate.ids(offset, limit)
    end

    def initialize(aggregate_id, aggregate_type = EventStore.table_name)
      @aggregate = Aggregate.new(aggregate_id, aggregate_type)
    end

    def exists?
      aggregate.snapshot_exists?
    end

    def id
      aggregate.id
    end

    def type
      aggregate.type
    end

    def event_table
      aggregate.event_table
    end

    def append(event_data)
      aggregate.append(event_data)
      yield(event_data) if block_given?
      nil
    end

    def snapshot
      raw_snapshot
    end

    def event_stream
      translate_events(raw_event_stream)
    end

    def event_stream_from(version_number, max=nil)
      translate_events(aggregate.events_from(version_number, max))
    end

    def last_event_before(start_time, fully_qualified_names = [])
      translate_events(aggregate.last_event_before(start_time, fully_qualified_names))
    end

    def event_stream_between(start_time, end_time, fully_qualified_names = [])
      translate_events(aggregate.event_stream_between(start_time, end_time, fully_qualified_names))
    end

    def peek
      aggregate.last_event
    end

    def raw_snapshot
      aggregate.snapshot
    end

    def raw_event_stream
      aggregate.event_stream
    end

    def raw_event_stream_from version_number, max=nil
      aggregate.events_from(version_number, max)
    end

    def version
      aggregate.version
    end

    def count
      event_stream.length
    end

    def destroy!
      aggregate.delete_events!
      aggregate.delete_snapshot!
    end

    def rebuild_snapshot!
      aggregate.delete_snapshot!
      aggregate.rebuild_snapshot!
    end

    private

    attr_reader :aggregate

    def translate_events(event_hashs)
      event_hashs.map { |eh| translate_event(eh) }
    end

    def translate_event(event_hash)
      return if event_hash.empty?
      occurred_at = TimeHacker.translate_occurred_at_from_local_to_gmt(event_hash[:occurred_at])
      SerializedEvent.new event_hash[:fully_qualified_name], event_hash[:serialized_event], event_hash[:version], occurred_at
    end
  end
end
