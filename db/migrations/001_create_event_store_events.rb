require 'event_store'
Sequel.migration do
  up do

    run %Q<CREATE TABLE #{EventStore.fully_qualified_table} (
          id AUTO_INCREMENT PRIMARY KEY,
          version BIGINT NOT NULL,
          aggregate_id varchar(36) NOT NULL,
          fully_qualified_name varchar(255) NOT NULL,
          occurred_at TIMESTAMPTZ NOT NULL,
          serialized_event VARBINARY(1000) NOT NULL)

          PARTITION BY EXTRACT(year FROM occurred_at AT TIME ZONE 'UTC')*100 + EXTRACT(month FROM occurred_at AT TIME ZONE 'UTC');

          CREATE PROJECTION #{EventStore.fully_qualified_table}_super_projecion /*+createtype(D)*/
          (
           id ENCODING COMMONDELTA_COMP,
           version ENCODING COMMONDELTA_COMP,
           aggregate_id ENCODING RLE,
           fully_qualified_name ENCODING AUTO,
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
           FROM #{EventStore.fully_qualified_table}
           ORDER BY aggregate_id,
                    version
          SEGMENTED BY HASH(aggregate_id) ALL NODES
          KSAFE 1;

          CREATE PROJECTION #{EventStore.fully_qualified_table}_runtime_history_projection /*+createtype(D)*/
          (
           version ENCODING DELTAVAL,
           aggregate_id ENCODING RLE,
           fully_qualified_name ENCODING RLE,
           occurred_at ENCODING RLE,
           serialized_event ENCODING AUTO
          )
          AS
           SELECT version,
                  aggregate_id,
                  fully_qualified_name,
                  occurred_at,
                  serialized_event
           FROM #{EventStore.fully_qualified_table}
           ORDER BY aggregate_id,
                    occurred_at,
                    fully_qualified_name
           SEGMENTED BY HASH(aggregate_id) ALL NODES
           KSAFE 1;>
  end

  down do
    run 'DROP SCHEMA #{EventStore.schema} CASCADE;'
  end
end
