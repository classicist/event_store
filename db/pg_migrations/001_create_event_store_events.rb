require 'event_store'
Sequel.migration do
  change do
    create_table((EventStore.schema + "__" + EventStore.table_name).to_sym) do
      primary_key :id
      Bignum      :version
      index       :version
      String      :aggregate_id
      index       :aggregate_id
      String      :fully_qualified_name
      index       :fully_qualified_name
      DateTime    :occurred_at
      index       :occurred_at
      bytea       :serialized_event
    end
  end
end
