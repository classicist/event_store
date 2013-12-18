module EventStore
  class Aggregate

    def initialize id, type
      @id = id
      @type = type
    end

    def events
      @events ||= EventStore.db.from("#{@type}_events").where(:aggregate_id => @id.to_s).order(:version)
    end

    def current_state
      event_types.map { |et| events.where(:fully_qualified_name => et).last }
    end

    private

    def event_types
      events.order(nil).select(:fully_qualified_name).group(:fully_qualified_name).map{ |e| e[:fully_qualified_name] }
    end

  end
end