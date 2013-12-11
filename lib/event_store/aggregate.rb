module EventStore
  class Aggregate

    def initialize id, type
      @id = id
      @type = type
    end

    def events
      @events ||= event_class.for_aggregate(@id)
    end

    def last_event_of_type event_type
      events.of_type(event_type).last
    end

    def last_event
      events.last
    end

    def event_class
      if EventStore.const_defined?(event_class_name)
        EventStore.const_get(event_class_name)
      else
        event_table_name = "#{@type}_events"
        typed_event_class = Class.new(EventStore::Event) do
          set_dataset from(event_table_name).order(:version)
        end
        EventStore.const_set(event_class_name, typed_event_class)
      end
    end

    private

    def event_class_name
      @event_class_name ||= "#{@type.to_s.capitalize}Event"
    end

  end
end