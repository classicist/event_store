require 'event_store'
Sequel.migration do
  up do
    schema = 'events'
    run %Q< CREATE SCHEMA #{schema};

          #{EventStore.event_table_creation_ddl.gsub(';', '')}
          PARTITION BY EXTRACT(year FROM occurred_at)*100 + EXTRACT(month FROM occurred_at);

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
          SEGMENTED BY HASH (aggregate_id) ALL NODES;>
  end

  down do
    run 'DROP SCHEMA #{schema} CASCADE;'
  end
end
