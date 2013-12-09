# EventStore

Ruby implementation of an EventSource (A+ES) for the Nexia Ecosystem.

# Usage

Currently, `EventStore` supports `sqlite`, `postgres`, and `vertica` adapters. Define your adapter and the connection parameters in the `EventStore` configure block.

### Connecting
```ruby
EventStore.configure do
  adapter  :vertica
  database "my_database"
  host     "db.example.com"
  username "user1234"
  password "password"
  port      5432
end
```

### Notes on Connecting

- `sqlite` only requires one connection parameter, `database`. This is the path to your database file.
- `postgres` will assume a port of `5432` if one is not supplied.

### Creating a client

```ruby
client = EventStore::Client.new(aggregate_id)

# Get an aggregate's event stream
client.event_stream

# Get an aggregate's event stream starting from a sequence number
client.event_stream_from(347)

# event_stream_from optionally takes a limit
client.event_stream_from(347, 1000)

# Get the last event for an aggregate
client.peek

# Append events to an aggregate's event stream
client.append(events, expected_sequence_number)
```

### Migrating your database

With the `sequel` gem installed, you have access to its command line tool. To migrate your database, enter the following command:
`$ sequel -m path/to/migrations/folder postgres://username:password@localhost:5432/event_store_test`

- The first argument is the path to the folder containing migrations, not a specific file. An example migration can be found at [001_create_event_store_events.rb](https://github.com/nexiahome/event_store/blob/master/db/migrations/001_create_event_store_events.rb)
- The second argument is your full database connection url
