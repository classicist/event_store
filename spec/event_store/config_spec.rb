require 'spec_helper'

describe "Configuration" do
  it "should do nothing if you try to clear! without a connected db" do
    allow(EventStore).to receive(:db).and_return(nil)
    expect {EventStore.clear!}.not_to raise_error
  end
end