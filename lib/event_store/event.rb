module EventStore
  class Event < Sequel::Model(:event_store_events)

    dataset_module do
      def for_device(device_id)
        where device_id: device_id.to_s
      end

      def from_sequence_number(seq_nbr)
        where sequence_number: seq_nbr.to_i
      end
    end

    @@required_attributes = %w{ device_id name sequence_number occurred_at data }

    def validate
      super
      @@required_attributes.each do |attribute_name|
        errors.add(attribute_name, "can't be null") if send(attribute_name).nil?
      end
    end

  end
end
