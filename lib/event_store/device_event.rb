module EventStore
  class DeviceEvent < Event

    set_dataset from(:device_events).order(:version)

  end
end