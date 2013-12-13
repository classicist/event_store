module EventStore
  class Snapshot < Sequel::Model(:event_store_snapshots)

    PACKING_FORMAT = 'U'

    def self.latest_for_aggregate(aggregate)
      where(:aggregate_id => aggregate.id, :aggregate_type => aggregate.type.to_s).order(Sequel.desc(:id)).limit(1).first
    end
    def self.last_snapshot(aggregate)
      where(:aggregate_id => aggregate.id).order(Sequel.desc(:id)).limit(1).first
    end

    def event_ids
      self[:event_ids].unpack(PACKING_FORMAT)
    end

    def event_ids=(ids)
      self[:event_ids] = ids.pack(PACKING_FORMAT)
    end

    def event_types
      aggregate.events.where(:version => event_ids).map(&:fully_qualified_name)
    end

    private

    def aggregate
      @aggregate ||= Aggregate.new(aggregate_id, aggregate_type)
    end

  end
end