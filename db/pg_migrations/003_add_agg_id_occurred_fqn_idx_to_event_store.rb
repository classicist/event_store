require 'event_store'
Sequel.migration do
  no_transaction
  change do
    idx_name = "#{EventStore.schema}_#{EventStore.table_name}_aggregate_id_occurred_at_name_idx"
    alter_table(Sequel.qualify(EventStore.schema, EventStore.table_name)) do
      add_index([:aggregate_id, :occurred_at, :fully_qualified_name], name: idx_name, concurrently: true)
    end
  end
end
