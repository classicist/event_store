module EventStore
  class Aggregate

    attr_reader :id, :type

    def initialize id, type
      @id = id
      @type = type
    end

    def events
      @events ||= event_class.for_aggregate(@id)
    end

    def last_event_of_type event_type
      events.of_type(event_type).order(Sequel.desc(:version)).limit(1).first
    end

    def last_event
      events.order(Sequel.desc(:version)).limit(1).first
    end

    def event_class
      if EventStore.const_defined?(event_class_name)
        EventStore.const_get(event_class_name)
      else
        event_table_name = "#{@type}_events"
        typed_event_class = Class.new(EventStore::Event) do
          set_dataset from(event_table_name)
        end
        EventStore.const_set(event_class_name, typed_event_class)
      end
    end

    def all_event_types(snapshot)
      snapshot_event_types = events.where(:version => snapshot.event_ids).map(&:fully_qualified_name)
      recent_event_types = event_types_since(snapshot.event_ids.max)
      snapshot_event_types | recent_event_types
    end

    def current_state
      snapshot = Snapshot.latest_for_aggregate(self)
      if snapshot
        event_types = all_event_types snapshot
      else
        event_types = event_types_since(0)
      end
      event_types.map { |et| last_event_of_type(et) }
    end

    def event_types_since(event_version)
      events.where('version > ?', event_version).select(:fully_qualified_name).group(:fully_qualified_name).map(&:fully_qualified_name)
    end

    def event_class_name
      @event_class_name ||= "#{@type.to_s.capitalize}Event"
    end

  end
end