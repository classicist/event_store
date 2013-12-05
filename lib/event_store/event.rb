module EventStore
  class Event < Sequel::Model(:event_store_events)

    dataset_module do
      def for_device(device_id)
        where device_id: device_id.to_s
      end

      def from_sequence(seq_nbr)
        where sequence_number: seq_nbr.to_i
      end
    end

    @@required_attributes = %w{ device_id fully_qualified_name sequence_number occurred_at data }

    def validate
      super
      @@required_attributes.each do |attribute_name|
        errors.add(attribute_name, "is required") if send(attribute_name).to_s.strip.empty?
      end
    end

  end
end
