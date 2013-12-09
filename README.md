event_store
===========

Ruby implementation of an EventSource (A+ES) for the Nexia Ecosystem

# Usage

### Connecting
```ruby
EventStore.configure do
  adapter  :vertica
  database "my_database"
  host     "host"
  username "user1234"
  password "password"
  port      5432
end
```

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
