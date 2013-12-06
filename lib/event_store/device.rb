module EventStore
  class Device

    def initialize(id)
      @id = id
    end

    def events
      @events ||= Event.for_device(@id)
    end

  end
end