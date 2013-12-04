require_relative '../minitest_helper'
require 'event_store'

describe EventStore::Event do
  subject { EventStore::Event }

  describe "#validate" do

    [:device_id, :name, :sequence_number, :occurred_at, :data].each do |attr|
      it "requires #{attr}" do
        refute subject.new(attr => nil).valid?
        refute subject.new(attr => "   ").valid?
        refute subject.new(attr => "").valid?
      end
    end

  end
end
