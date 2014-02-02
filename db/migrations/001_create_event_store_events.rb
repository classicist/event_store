Sequel.migration do
  up do
    run 'CREATE SCHEMA events;
          CREATE TABLE events.device_events (
            id auto_increment NOT NULL,
            version BIGINT NOT NULL,
            aggregate_id varchar(36) NOT NULL,
            fully_qualified_name varchar(255) NOT NULL,
            occurred_at DATETIME NOT NULL,
            serialized_event VARBINARY NOT NULL)
          ORDER BY aggregate_id, fully_qualified_name, version
          SEGMENTED BY HASH(aggregate_id) ALL NODES
          PARTITION BY MONTH(occurred_at);'
  end

  down do
    run 'DROP SCHEMA events CASCADE;'
  end
end
