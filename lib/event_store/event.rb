module EventStore
  class Event < Sequel::Model

    REQUIRED_ATTRIBUTES = %w{ aggregate_id fully_qualified_name occurred_at data }

    dataset_module do
      def for_aggregate aggregate_id
        where :aggregate_id => aggregate_id.to_s
      end

      def starting_from_version version_number
        where { version >= version_number.to_i }
      end

      def of_type type
        where :fully_qualified_name => type
      end
    end

    def validate
      super
      REQUIRED_ATTRIBUTES.each do |attribute_name|
        errors.add(attribute_name, "is required") if send(attribute_name).to_s.strip.empty?
      end
    end

  end
end
