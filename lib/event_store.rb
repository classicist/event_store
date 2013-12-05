require 'event_store/version'
require 'event_store/configuration'
require 'event_store/event_serializer'

module EventStore
  attr_reader :config

  def self.configure &block
    config.instance_eval &block
    config.connect_to_db
    require 'event_store/client'
    require 'event_store/event'
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.db
    Event.db
  end
end
