module EventStore
  class Device

    def initialize(id)
      @id = id
    end

    def event_stream
      Event.for_device(@id).order(:occurred_at)
    end

  end
end
