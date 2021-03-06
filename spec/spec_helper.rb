require 'simplecov'
require 'simplecov-rcov'
require 'pry'
require 'rspec'

class SimpleCov::Formatter::MergedFormatter
  def format(result)
     SimpleCov::Formatter::HTMLFormatter.new.format(result)
     SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

SimpleCov.start do
  add_filter "/spec/"
  add_filter 'lib/event_store.rb'
  SimpleCov.minimum_coverage 95
end

require 'event_store'

EventStore.postgres

RSpec.configure do |config|
  config.after(:each) do
    EventStore.clear!
  end
end