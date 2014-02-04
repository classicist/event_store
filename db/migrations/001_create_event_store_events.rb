Sequel.migration do
  up do
    run ' CREATE SCHEMA events;
          CREATE TABLE events.device_events (
            id auto_increment NOT NULL,
            version BIGINT NOT NULL,
            aggregate_id varchar(36) NOT NULL,
            fully_qualified_name varchar(255) NOT NULL,
            occurred_at DATETIME NOT NULL,
            serialized_event VARBINARY(255) NOT NULL);

          CREATE PROJECTION events.device_events_DBD_1_seg_EventStore9_b0 /*+basename(device_events_DBD_1_seg_EventStore9),createtype(D)*/
          (
           id ENCODING DELTAVAL,
           version ENCODING DELTAVAL,
           aggregate_id ENCODING RLE,
           fully_qualified_name ENCODING RLE,
           occurred_at ENCODING BLOCKDICT_COMP,
           serialized_event ENCODING AUTO
          )
          AS
           SELECT id,
                  version,
                  aggregate_id,
                  fully_qualified_name,
                  occurred_at,
                  serialized_event
           FROM events.device_events
           ORDER BY aggregate_id,
                    fully_qualified_name,
                    version
          PARTITION BY MONTH(occurred_at)
          SEGMENTED BY HASH (aggregate_id) ALL NODES;'
  end

  down do
    run 'DROP SCHEMA events CASCADE;'
  end
end
