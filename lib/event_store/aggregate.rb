module EventStore
  class Aggregate

    attr_reader :id, :type

    def initialize id, type
      @id = id.to_s
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

    def current_state
      snapshot = Snapshot.latest_for_aggregate(self)
      if snapshot
        recent_events = most_recent_events_per_type_since(snapshot.event_ids.max)
        missing_event_types = snapshot.event_types - recent_events.map(&:fully_qualified_name)
        [recent_events, snapshot.events.where(:fully_qualified_name => missing_event_types)].map(&:to_a).inject(&:+)
      else
        most_recent_events_per_type_since(0).to_a
      end
    end

    private

    def most_recent_events_per_type_since(event_version)
      recent_event_versions = event_class.db.fetch("SELECT MAX(version) AS version FROM #{event_class.table_name} WHERE aggregate_id=? AND version > ? GROUP BY fully_qualified_name", @id, event_version)
      events.where(:version => recent_event_versions)
    end

    def event_class_name
      @event_class_name ||= "#{@type.to_s.capitalize}Event"
    end

  end
end