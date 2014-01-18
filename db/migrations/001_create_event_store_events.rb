Sequel.migration do
  change do
    create_table(:device_events) do
      primary_key :version, :index
      String      :aggregate_id, :index
      String      :fully_qualified_name, :index
      DateTime    :occurred_at, :index
      bytea       :data
    end
  end
end
