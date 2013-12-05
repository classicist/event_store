require 'event_store/version'
require 'event_store/configuration'

module EventStore
  attr_reader :config

  def self.configure &block
    config.instance_eval &block
    require 'event_store/client'
    require 'event_store/event'
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.db
    config.db
  end
end
