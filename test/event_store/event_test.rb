require_relative '../minitest_helper'

describe EventStore::Event do
  subject { EventStore::Event }

  describe "#validate" do

    [:device_id, :name, :data].each do |attr|
      it "requires #{attr}" do
        refute subject.new(attr => nil).valid?
        refute subject.new(attr => "   ").valid?
        refute subject.new(attr => "").valid?
      end
    end


    [:sequence_number, :occurred_at].each do |attr|
      # throws error on "    "
      it "requires #{attr}" do
        refute subject.new(attr => "").valid?
        refute subject.new(attr => nil).valid?
      end
    end

  end
end
