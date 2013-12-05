module EventStore
  class EventSerializer

    def initialize event
      @event = event
      @serialized = {}
    end

    def serialize
      @serialized[:device_id]            = @event.header.device_id
      @serialized[:occurred_at]          = @event.header.occurred_at
      @serialized[:data]                 = @event.to_s
      @serialized[:fully_qualified_name] = @event.fully_qualified_name
      @serialized
    end

  end
end