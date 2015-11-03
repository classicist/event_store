require "spec_helper"

module EventStore
  describe "unescape_bytea" do
    let(:original_string) { "the original string" }

    context "when the string has been escaped once" do
      let(:escaped_string) { EventStore.escape_bytea(original_string) }

      it "returns the original string" do
        expect(EventStore.unescape_bytea(escaped_string)).to eq(original_string)
      end
    end

    context "when the string has been escaped twice" do
      let(:escaped_string) { "x" + EventStore.escape_bytea(EventStore.escape_bytea(original_string)) }

      it "returns the original string" do
        expect(EventStore.unescape_bytea(escaped_string)).to eq(original_string)
      end
    end
  end
end
