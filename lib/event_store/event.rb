module EventStore
  class Event < Sequel::Model(:event_store_events)

    set_dataset order(:sequence_number)

    dataset_module do
      def for_aggregate aggregate_id
        where :aggregate_id => aggregate_id.to_s
      end

      def starting_from_sequence_number seq_nbr
        where { sequence_number >= seq_nbr.to_i }
      end

      def of_type type
        where :fully_qualified_name => type
      end
    end

    @@required_attributes = %w{ aggregate_id fully_qualified_name occurred_at data }

    def validate
      super
      @@required_attributes.each do |attribute_name|
        errors.add(attribute_name, "is required") if send(attribute_name).to_s.strip.empty?
      end
    end

  end
end
