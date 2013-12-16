module EventStore
  class Aggregate

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
      recent_event_versions = event_class.db.fetch("SELECT MAX(version) AS version FROM #{event_class.table_name} WHERE aggregate_id=? GROUP BY fully_qualified_name", @id)
      events.where(:version => recent_event_versions).to_a
    end

    private

    def event_class_name
      @event_class_name ||= "#{@type.to_s.capitalize}Event"
    end

  end
end