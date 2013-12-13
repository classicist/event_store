require_relative '../spec_helper'

describe EventStore::Aggregate do

  before do
    @aggregate = EventStore::Aggregate.new(12, :device)
    (1..10).each do |i|
      @aggregate.event_class.create :aggregate_id => 12, :occurred_at => DateTime.now, :data => 234532.to_s(2), :fully_qualified_name => "e_#{i}"
    end
  end

  describe "#current_state" do
    it "with no pre-existing snapshot" do
      expect(@aggregate.current_state).to match_array(@aggregate.events.to_a)
    end

    describe "with a pre-existing snapshot" do
      before do
        EventStore::Snapshot.create :aggregate_id => @aggregate.id, :aggregate_type => @aggregate.type, :event_ids => @aggregate.events.map(&:version)
      end

      describe "that holds all the most recent events" do
        it "should return all of the events from that snapshot" do
          expect(@aggregate.current_state).to match_array(@aggregate.events.to_a)
        end
      end

      describe "that holds some of the most recent events" do
        it "should get events from the snapshot and the events with new types" do
          (11..15).each do |i|
            @aggregate.event_class.create :aggregate_id => 12, :occurred_at => DateTime.now, :data => 234532.to_s(2), :fully_qualified_name => "e_#{i}"
          end
          expect(@aggregate.current_state).to match_array(@aggregate.events.to_a)
        end

        it "should get some events from the snapshot mixed with newer events of the same type" do
          new_events = (1..5).map do |i|
            @aggregate.event_class.create :aggregate_id => 12, :occurred_at => DateTime.now, :data => 234532.to_s(2), :fully_qualified_name => "e_#{i}"
          end
          expect(@aggregate.current_state).to match_array(new_events + @aggregate.events.where(:fully_qualified_name => (6..10).map{|i| "e_#{i}"}).to_a)
        end
      end
    end
  end
end