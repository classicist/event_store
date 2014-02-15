# EventStore

A fast, production ready Ruby implementation of an EventStore (A+ES).
For more detail on what an EventStore is checkout what Gregg Young has to stay about it:
http://codebetter.com/gregyoung/2010/02/20/why-use-event-sourcing/

# Usage

Currently, `EventStore` supports `postgres` and `vertica` adapters.

### Connecting in Development or Test
```ruby
EventStore.postgres(:development)
EventStore.postgres #test

EventStore.vertica(:development)
EventStore.vertica #test
```

### Connecting in Production or Elsewhere
```ruby
EventStore.custom_config(redis_config, database_config)
#The redis and database configs are the standard hashes expected by the Redis.new and Sequel.connect -- we just pass them directly in
```

### Notes on Connecting

- `EventStore` expects a database called `history_store` to exist.
- `postgres` will try to connect in dev and test mode as 'nexia:Password1@localhost'
- `postgres` will assume a port of `5432` if one is not supplied.

- `vertica` expects to find an environment variable (VERTICA_HOST) to be set and will use this as the host in dev and test mode
- `vertica` will assume its default port if one is not supplied.
- `vertica` will try to connect in dev and test mode as 'dbadmin:password@[vertica_host]'
- To find the ip address of vertica on your local box (running in a vm):
  1. open Settings -> Network and select Wi-Fi
  2. open a terminal in the VM
  3. do /sbin/ifconfig (ifconfig is not in $PATH)
  4. the inet address for en0 is what you want
  Hint: if it just hangs, you have have the wrong IP


### Caveat Emptor  
`redis`, by default, is using database 15. Running the tests will DROP this database every time they run. 

### Usage

```ruby
client = EventStore::Client.new(aggregate_id)

# transactionally append an array events to an aggregate's event stream
client.append(events)

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

# Get the current version of an aggregate
client.version

# Drop all events associated with an aggregate, including its snapshot
client.destroy!

# Drop all events associated with ALL aggregate
EventStore.clear!
```

### Rspec
To have event_store cleanup between tests, put this in your spec_helper.rb:
```ruby
require 'event_store'

EventStore.postgres

RSpec.configure do |config|
  config.after(:each) do
    EventStore.clear!
  end
end
```
