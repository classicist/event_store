Sequel.migration do
  change do
    create_table(:device_events) do
      primary_key :version
      String      :aggregate_id
      String      :fully_qualified_name
      DateTime    :occurred_at
      bytea       :data
    end
  end
end
