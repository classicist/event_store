require "logger"

module EventStore
  class Snapshot
    include Enumerable

    attr_reader :snapshot_version_table, :snapshot_table

    def initialize aggregate
      @aggregate = aggregate
      @redis = EventStore.redis
      @snapshot_table = "#{@aggregate.type}_snapshots_for_#{@aggregate.id}"
      @snapshot_version_table = "#{@aggregate.type}_snapshot_versions_for_#{@aggregate.id}"
    end

    def exists?
      @redis.exists(snapshot_table)
    end

    def last_event
      to_a.last
    end

    def version(snapshot_key =:current_version)
      (@redis.hget(snapshot_version_table, snapshot_key) || -1).to_i
    end

    def version_for(fully_qualified_name, sub_key = nil)
      version(snapshot_key(fully_qualified_name: fully_qualified_name, sub_key: sub_key))
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
        version                 = raw_event.first.to_i
        serialized_event        = EventStore.unescape_bytea(raw_event[1])
        occurred_at             = Time.parse(raw_event.last)
        snapshot + [SerializedEvent.new(fully_qualified_name, serialized_event, version, occurred_at)]
      end
      logger.debug { "#{self.class.name} serializing events took #{Time.now - t} seconds" }
      result_hash.sort_by(&:version).each { |e| yield e }
    end

    def rebuild_snapshot!(logger=default_logger)
      logger.info { "#{self.class.name}#rebuild_snapshot!" }
      t = Time.now
      delete_snapshot!
      logger.debug { "Deleting snapshot took #{Time.now - t} seconds" }
      t = Time.now
      all_events = @aggregate.events.all
      logger.debug { "getting all events took #{Time.now - t} seconds" }
      t = Time.now
      corrected_events = all_events.map{|e| e[:occurred_at] = TimeHacker.translate_occurred_at_from_local_to_gmt(e[:occurred_at]); e}
      logger.debug { "correcting occurred_at on all events took #{Time.now - t} seconds" }
      t = Time.now
      store_snapshot(corrected_events)
      logger.debug { "storing new snapshot took #{Time.now - t} seconds" }
    end

    def delete_snapshot!
      EventStore.redis.del [snapshot_table, snapshot_version_table]
    end

    def store_snapshot(prepared_events)
      valid_snapshot_events = []
      valid_snapshot_versions = []

      prepared_events.each do |event_hash|
        if event_hash[:version].to_i > current_version_numbers[snapshot_key(event_hash)].to_i
          valid_snapshot_events   += snapshot_event(event_hash)
          valid_snapshot_versions += snapshot_version(event_hash)
        end
      end

      unless valid_snapshot_versions.empty?
        valid_snapshot_versions += [:current_version, valid_snapshot_versions.last.to_i]

        @redis.multi do
          @redis.hmset(snapshot_version_table, valid_snapshot_versions)
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
        [ event[:version].to_s,
          event[:serialized_event],
          event[:occurred_at].to_s
        ].join(EventStore::SNAPSHOT_DELIMITER)
      ]
    end

    def snapshot_version(event)
      [
        snapshot_key(event),
        event[:version]
      ]
    end

    def current_version_numbers
      current_versions = @redis.hgetall(snapshot_version_table)
      current_versions.default = -1
      current_versions
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
      event = @aggregate.events.select(:version).limit(1).all
      logger.debug { "#{self.class.name} took #{Time.now - t} seconds query db for version" }
      return events_hash if event.empty? #return nil if no events in the ES

      # so there are events in the ES but there is no redis snapshot
      rebuild_snapshot!(logger)
      events_hash = read_raw_snapshot(logger)
    end
  end
end
