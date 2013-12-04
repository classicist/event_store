Sequel.migration do
  change do
    create_table(:event_store_events) do
      primary_key :id
      String      :device_id
      String      :name
      Integer     :sequence_number
      DateTime    :occurred_at
      bytea       :data
    end
  end
end
