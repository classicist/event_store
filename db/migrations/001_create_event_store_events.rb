DB.extension :pg_hstore
Sequel.migration do
  change do
    create_table(:device_events) do
      primary_key :version
      index       :version
      String      :aggregate_id
      index       :aggregate_id
      String      :fully_qualified_name
      index       :fully_qualified_name
      DateTime    :occurred_at
      index       :occurred_at
      bytea       :data
    end

    create_table(:device_snapshots) do
      Bignum      :version
      String      :aggregate_id, primary_key: true
      index       :aggregate_id, unique: true
      column      :snapshot, :hstore
    end
  end
end
