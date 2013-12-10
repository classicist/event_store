module EventStore
  class Aggregate

    attr_reader :event_class

    def initialize id, event_class
      @id = id
      @event_class = event_class
    end

    def events
      @events ||= event_class.for_aggregate(@id)
    end

    def last_event_of_type type
      events.of_type(type).last
    end

    def last_event
      events.last
    end

  end
end