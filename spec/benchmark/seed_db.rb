require 'event_store'

EventStore.connect :adapter => :postgres, :database => 'event_store_performance', :host => 'localhost'

DEVICES = 1000
EVENTS_PER_DEVICE = 5_000
EVENT_TYPES = 1000

event_types = Array.new(EVENT_TYPES) { |i| "event_type_#{i}" }
events_table = EventStore.db[:device_events]
records = []

puts "Creating #{DEVICES} Aggregates with #{EVENTS_PER_DEVICE} events each. There are #{EVENT_TYPES} types of events."

(1..DEVICES).each do |device_id|
  EVENTS_PER_DEVICE.times do
    records << {aggregate_id: device_id.to_s, fully_qualified_name: event_types.sample, data: 9999999999999.to_s(2), occurred_at: DateTime.now}
  end
  if device_id % 1000 == 0
    puts "Created events for #{device_id} of #{DEVICES} Aggregates"
    puts "Inserting #{EVENTS_PER_DEVICE * DEVICES} events into database"
    events_table.multi_insert(records)
    records = []
  end
end



