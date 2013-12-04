module EventStore
  class Device

    def initialize(id)
      @id = id
    end

    def event_stream
      Event.for_device(@id).order(:occurred_at)
    end

    def sequence(seq_nbr)
      event_stream.from_sequence_number(seq_nbr)
    end

  end
end
