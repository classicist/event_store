# require_relative '../../protocol_buffers/lib/protocol_buffers'
require 'faceplate_api/thermostats/test_support'
require 'securerandom'
event_names = [:firmware_version_updated, :fan_on_updated, :fan_mode_updated, :configuration_lock_updated, :display_lock_updated,
 :mode_updated, :system_name_updated, :operation_status_updated, :relative_airflow_updated, :balance_point_updated, :indoor_temperature_updated,
 :temperature_setpoint_updated, :sensor_added, :sensor_removed, :sensor_updated, :zone_added, :zone_removed, :zone_updated, :preset_added,
 :preset_removed, :preset_updated, :preset_activated, :relative_humidity_setpoint_updated, :weekly_schedule_added, :weekly_schedule_updated,
 :weekly_schedule_removed, :weekly_schedule_activated, :event_schedule_added, :event_schedule_removed, :event_schedule_updated, :event_schedule_activated]

aggregate_ids = ["ASDFDS12939", "1SQFDS12B39", "103MMV", SecureRandom.uuid, SecureRandom.uuid, "10PM93BU37"]
aggregate_ids.each do |aggregate_id|
event_mother = EventMother.new(aggregate_id)
  event_names.each_with_index do |name, version|
      event = event_mother.send(name)
      puts "INSERT INTO event.device_events('aggregate_id', 'version', 'occurred_at', 'serialized_event', 'fully_qualified_name') values (#{aggregate_id}, #{version}, #{DateTime.now.iso8601}, #{event.to_s}, #{name})"
    end
end