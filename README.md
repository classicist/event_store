# EventStore

Ruby implementation of an EventSource (A+ES) for the Nexia Ecosystem.

# Usage

Currently, `EventStore` supports `postgres` and `vertica` adapters.

### Connecting in Development or Test
```ruby
EventStore.postgres(:development)
EventStore.postgres #test

EventStore.vertica(:development)
EventStore.vertica #test

#Production
EventStore.connect_db(redis_config, database_config) #The redis and database configs are the standard hashes expected by the databases -- we just pass them directly in
```

### Notes on Connecting

- `EventStore` expects a database called `history_store` to exist.
- `postgres` will try to connect in dev and test mode as 'nexia:Password1@localhost'
- `postgres` will assume a port of `5432` if one is not supplied.

- `vertica` expects to find an environment variable (VERTICA_HOST) to be set and will use this as the host in dev and test mode
- `vertica` will assume its default port if one is not supplied.
- `vertica` will try to connect in dev and test mode as 'dbadmin:password@[vertica_host]'


### Creating a client

```ruby
client = EventStore::Client.new(aggregate_id)

# Get a list of events representing a snapshot of the aggregate's current state (fast)
client.snapshot

# Get an aggregate's entire event stream (can be very large)
client.event_stream

# Get an aggregate's event stream starting from a version
client.event_stream_from(347)

# event_stream_from optionally takes a limit
client.event_stream_from(347, 1000)

# Get the last event for an aggregate
client.peek

# Append events to an aggregate's event stream
client.append(events, expected_version)

# Get the current version of an aggregate
client.version

# Drop all the events associated with an aggregate, including its snapshot
client.destroy!
```