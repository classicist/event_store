# require_relative '../../protocol_buffers/lib/protocol_buffers'
require 'faceplate_api'
require "faceplate_api/thermostats/test_support"
require 'securerandom'
require 'time'
include FaceplateApi
event_names = [:firmware_version_updated, :fan_on_updated, :fan_mode_updated, :configuration_lock_updated, :display_lock_updated,
 :mode_updated, :system_name_updated, :operation_status_updated, :relative_airflow_updated, :balance_point_updated, :indoor_temperature_updated,
 :temperature_setpoint_updated, :sensor_added, :sensor_removed, :sensor_updated, :zone_added, :zone_removed, :zone_updated, :preset_added,
 :preset_removed, :preset_updated, :preset_activated, :relative_humidity_setpoint_updated, :event_schedule_added, :event_schedule_removed, :event_schedule_updated, :event_schedule_activated]

aggregate_ids = ["ASDFDS12939", "1SQFDS12B39", "103MMV", SecureRandom.uuid, SecureRandom.uuid, "10PM93BU37"]
ITERATIONS = 5
versions_per_device = (0..(event_names.length * ITERATIONS)).to_a

mothers = {}
aggregate_ids.each do |aggregate_id|
  mother  = FaceplateApi::EventFixture.new(header: {device_id: aggregate_id}).event_mother
  mothers[mother] = versions_per_device.dup
end

File.open('./data.sql', 'w') do |f|
  (event_names * ITERATIONS * ITERATIONS).shuffle.each do |name|
    event_mother = mothers.keys.sample
    event = event_mother.send(name)
    version = mothers[event_mother].shift
    f.puts "INSERT INTO events.device_events(aggregate_id, version, occurred_at, serialized_event, fully_qualified_name) values ('#{event_mother.device_id}', #{version}, '#{DateTime.now.iso8601}', '#{event.to_s}', '#{name}');"
  end
  f.puts 'commit;'
end