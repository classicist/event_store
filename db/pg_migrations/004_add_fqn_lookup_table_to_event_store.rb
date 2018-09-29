require 'event_store'
Sequel.migration do
  no_transaction

  event_store_table = Sequel.qualify(EventStore.schema, EventStore.table_name)
  lookup_table =      Sequel.qualify(EventStore.schema, EventStore.lookup_table_name)

  event_store_table_name = EventStore.schema + '.' + EventStore.table_name
  lookup_table_name      = EventStore.schema + '.' + EventStore.lookup_table_name

  up do
    create_table(lookup_table) do
      primary_key :id
      String :fully_qualified_name, null: false, unique: true
      index  :fully_qualified_name
    end

    run <<-"EOSQL"
      INSERT INTO #{lookup_table_name} (fully_qualified_name)
        SELECT DISTINCT fully_qualified_name FROM #{event_store_table_name}
    EOSQL

    alter_table(event_store_table) do
      idx_name = "aggregate_id_occurred_at_fqn_id_idx"
      add_foreign_key :fully_qualified_name_id, lookup_table, key: :id
      add_index([:aggregate_id, :occurred_at, :fully_qualified_name_id], name: idx_name)
    end

    run <<-"EOSQL"
      UPDATE #{event_store_table_name} AS event_store
         SET fully_qualified_name_id = lookup.id
        FROM #{lookup_table_name} AS lookup
       WHERE lookup.fully_qualified_name = event_store.fully_qualified_name
    EOSQL

    alter_table(event_store_table) do
      set_column_not_null :fully_qualified_name_id

      old_idx_name = "#{EventStore.schema}_#{EventStore.table_name}_aggregate_id_occurred_at_name_idx"
      drop_index [:aggregate_id, :occurred_at, :fully_qualified_name], name: old_idx_name
      drop_index :fully_qualified_name
      drop_column :fully_qualified_name
    end
  end

  down do
    alter_table(event_store_table) do
      idx_name = "#{EventStore.schema}_#{EventStore.table_name}_aggregate_id_occurred_at_name_idx"
      old_idx_name = "aggregate_id_occurred_at_fqn_id_idx"

      add_column :fully_qualified_name, String
      add_index :fully_qualified_name
      add_index([:aggregate_id, :occurred_at, :fully_qualified_name], name: idx_name)
      drop_index old_idx_name
    end

    run <<-"EOSQL"
      UPDATE #{event_store_table_name} AS event_store
         SET fully_qualified_name = lookup.fully_qualified_name
        FROM #{lookup_table_name} AS lookup
       WHERE lookup.id = event_store.fully_qualified_name_id
    EOSQL

    alter_table(event_store_table) do
      drop_foreign_key :fully_qualified_name_id
    end

    drop_table(lookup_table)
  end
end
