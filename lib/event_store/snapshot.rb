require "logger"

module EventStore
  class Snapshot
    include Enumerable

    attr_reader :snapshot_event_id_table, :snapshot_table

    def initialize aggregate
      @aggregate = aggregate
      @redis = EventStore.redis
      @snapshot_table = "#{@aggregate.type}_snapshots_for_#{@aggregate.id}"
      @snapshot_event_id_table = "#{@aggregate.type}_snapshot_event_ids_for_#{@aggregate.id}"
    end

    def exists?
      @redis.exists(snapshot_table)
    end

    def last_event
      to_a.last
    end

    def event_id(snapshot_key =:current_event_id)
      (@redis.hget(snapshot_event_id_table, snapshot_key) || -1).to_i
    end

    def event_id_for(fully_qualified_name, sub_key = nil)
      event_id(snapshot_key(fully_qualified_name: fully_qualified_name, sub_key: sub_key))
    end

    def count(logger=default_logger)
      auto_rebuild_snapshot(read_raw_snapshot(logger), logger).count
    end

    def each(logger=default_logger)
      logger.info { "#{self.class.name}#each for #{@aggregate.id}" }
      t = Time.now
      events_hash = auto_rebuild_snapshot(read_raw_snapshot(logger), logger)
      logger.debug { "#{self.class.name}#auto_rebuild_snapshot took #{Time.now - t} seconds for #{@aggregate.id}" }

      t = Time.now
      result_hash = events_hash.inject([]) do |snapshot, (key, value)|
        fully_qualified_name, _ = key.split(EventStore::SNAPSHOT_KEY_DELIMITER)
        raw_event               = value.split(EventStore::SNAPSHOT_DELIMITER)
        event_id                = raw_event.first.to_i
        serialized_event        = EventStore.unescape_bytea(raw_event[1])
        occurred_at             = Time.parse(raw_event.last)
        snapshot + [SerializedEvent.new(fully_qualified_name, serialized_event, event_id, occurred_at)]
      end
      logger.debug { "#{self.class.name} serializing events took #{Time.now - t} seconds" }
      result_hash.sort_by(&:event_id).each { |e| yield e }
    end

    def rebuild_snapshot!(logger=default_logger)
      logger.info { "#{self.class.name}#rebuild_snapshot!" }
      t = Time.now
      delete_snapshot!
      logger.debug { "Deleting snapshot took #{Time.now - t} seconds" }
      t = Time.now
      all_events = @aggregate.snapshot_events.all
      logger.debug { "getting #{all_events.count} events" }
      logger.debug { "getting all events took #{Time.now - t} seconds" }
      t = Time.now
      corrected_events = all_events.map{|e| e[:occurred_at] = TimeHacker.translate_occurred_at_from_local_to_gmt(e[:occurred_at]); e}
      logger.debug { "correcting occurred_at on all events took #{Time.now - t} seconds" }
      t = Time.now
      store_snapshot(corrected_events)
      logger.debug { "storing new snapshot took #{Time.now - t} seconds" }
    end

    def delete_snapshot!
      EventStore.redis.del [snapshot_table, snapshot_event_id_table]
    end

    def store_snapshot(prepared_events, logger=default_logger)
      valid_snapshot_events = []
      valid_snapshot_event_ids = []

      prepared_events.each do |event_hash|
        key = snapshot_key(event_hash)
        current_id = current_event_id_numbers[key].to_i

        logger.debug("Snapshot#store_snapshot: snapshot_key: #{key} prepared id: #{event_hash[:id]}, current id: #{current_id}")
        if event_hash[:id].to_i > current_id
          logger.debug("prepared event is newer, storing")
          valid_snapshot_events    += snapshot_event(event_hash)
          valid_snapshot_event_ids += snapshot_event_id(event_hash)
        end
      end

      logger.debug("valid_snapshot_event_ids: #{valid_snapshot_event_ids.inspect}")
      unless valid_snapshot_event_ids.empty?
        logger.debug("there are valid_snapshot_event_ids, persisting to redis")
        valid_snapshot_event_ids += [:current_event_id, valid_snapshot_event_ids.last.to_i]

        @redis.multi do
          @redis.hmset(snapshot_event_id_table, valid_snapshot_event_ids)
          @redis.hmset(snapshot_table, valid_snapshot_events)
        end
      end
    end

  private

    def default_logger
      Logger.new('/dev/null')
    end

    def snapshot_key(event)
      [event[:fully_qualified_name], event[:sub_key] || EventStore::NO_SUB_KEY].join(EventStore::SNAPSHOT_KEY_DELIMITER)
    end

    def snapshot_event(event)
      [
        snapshot_key(event),
        [ event[:id].to_s,
          event[:serialized_event],
          event[:occurred_at].to_s
        ].join(EventStore::SNAPSHOT_DELIMITER)
      ]
    end

    def snapshot_event_id(event)
      [
        snapshot_key(event),
        event[:id]
      ]
    end

    def current_event_id_numbers
      @redis.hgetall(snapshot_event_id_table).tap { |event_ids|
        event_ids.default = -1
      }
    end

    def read_raw_snapshot(logger=default_logger)
      t = Time.now
      @redis.hgetall(snapshot_table).tap { |_snapshot|
        logger.debug { "#{self.class.name}#read_raw_snapshot took #{Time.now - t} seconds" }
      }
    end

    def auto_rebuild_snapshot(events_hash, logger=default_logger)
      logger.info { "#{self.class.name}#auto_rebuild_snapshot(#{events_hash.count} events)" }
      return events_hash unless events_hash.empty? #got it? return it

      t = Time.now
      logger.debug { "#{self.class.name} about to query db to see if anything is there" }
      event_count = @aggregate.events.count
      logger.debug { "#{self.class.name} took #{Time.now - t} seconds query db for event count" }
      return events_hash if event_count == 0 #return nil if no events in the ES

      # so there are events in the ES but there is no redis snapshot
      rebuild_snapshot!(logger)
      events_hash = read_raw_snapshot(logger)
    end
  end
end
