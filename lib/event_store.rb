require 'sequel'
require 'event_store/version'
require 'event_store/event_appender'
require 'event_store/aggregate'

module EventStore

  def self.db
    Event.db
  end

  def self.connect(*args)
    Sequel.connect(*args)
    require 'event_store/client'
    require 'event_store/event'
    require 'event_store/snapshot'
  end
end
