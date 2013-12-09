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
client = EventStore::Client.new(device_id)

# Get a device's event stream
client.event_stream

# Get a device's event stream starting from a sequence number
client.event_stream_from(347)

# event_stream_from optionally takes a limit
client.event_stream_from(347, 1000)

# Get the last event for a device
client.peek

# Append events to a device's event stream
client.append(events, expected_sequence_number)
```
