require "spec_helper"

describe EventStore do
  describe ".insert_table_name" do
    let(:date) { Date.parse("1955-01-31") }

    context "without partitioning defined" do
      let(:expected) { "es_test.test_events" }

      it "returns a properly formatted default table name" do
        expect(subject.insert_table_name(date)).to eq(expected)
      end
    end

    context "with partitioning defined" do
      let(:expected) { "es_test.test_events_1955_01_31" }
      let(:part_config) { { "schema" => "es_test", "table_name_suffix" => "_%Y_%m_%d", "partitioning" => true } }

      before { subject.custom_config(part_config, subject.local_redis_config, "test_events", "test") }
      after  { subject.custom_config(subject.raw_db_config["test"]["postgres"], subject.local_redis_config, "test_events", "test") }

      it "returns a properly formatted table name" do
        expect(subject.insert_table_name(date)).to eq(expected)
      end
    end
  end
end
