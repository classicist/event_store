Sequel.migration do
  change do
    create_table(:event_store_events) do
      primary_key :sequence_number
      String      :aggregate_id
      String      :fully_qualified_name
      DateTime    :occurred_at
      bytea       :data
    end
  end
end
