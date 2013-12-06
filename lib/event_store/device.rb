module EventStore
  class Device

    def initialize id
      @id = id
    end

    def events
      @events ||= Event.for_device(@id)
    end

    def last_event_of_type type
      events.of_type(type).last
    end

    def last_event
      events.last
    end

  end
end