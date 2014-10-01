require 'event_store'
Sequel.migration do
  change do
    alter_table((EventStore.schema + "__" + EventStore.table_name).to_sym) do
      add_column :sub_key, String
    end
  end
end
