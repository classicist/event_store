require 'event_store'
Sequel.migration do
  change do
    alter_table(Sequel.qualify(EventStore.schema, EventStore.table_name)) do
      add_column :sub_key, String
    end
  end
end
