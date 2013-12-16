require_relative '../spec_helper'

describe EventStore::Event do
  subject do
    EventStore::Aggregate.new(1, :device).event_class
  end

  describe "#validate" do

    [:aggregate_id, :fully_qualified_name, :data].each do |attr|
      it "requires #{attr}" do
        expect(subject.new(attr => nil)).to_not be_valid
        expect(subject.new(attr => "   ")).to_not be_valid
        expect(subject.new(attr => "")).to_not be_valid
      end
    end


    [:occurred_at].each do |attr|
      # throws error on "    "
      it "requires #{attr}" do
        expect(subject.new(attr => "")).to_not be_valid
        expect(subject.new(attr => nil)).to_not be_valid
      end
    end

  end

  describe '#db' do
    it 'should be the same as the EventStore#db' do
      expect(EventStore::Event.db).to equal(EventStore.db)
    end
  end
end
