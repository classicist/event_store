require 'sequel'
require 'event_store/version'

module EventStore
  def self.configure
    if block_given?
      yield Sequel::Model
      require 'event_store/client'
      require 'event_store/event'
    else
      raise LocalJumpError
    end
  end

  def self.db
    Sequel::Model.db
  end
end
