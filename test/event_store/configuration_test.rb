require_relative '../minitest_helper'

describe EventStore::Configuration do
  subject { EventStore::Configuration.new }
  it 'should set the credentials on the instance' do
    config = EventStore::Configuration.new
    config.instance_eval {
      credentials username: "username", password: "password", host: "host", port: "port", db_name: "db_name"
    }
    assert_equal "username", config.username
    assert_equal "port", config.port
  end

  describe '#adapter_settings' do
    it 'sqlite' do
      subject.instance_eval { db :sqlite }
      assert_equal 'sqlite', subject.adapter[:protocol]
    end

    it 'postgres' do
      subject.instance_eval { db :postgres }
      assert_equal 'postgres', subject.adapter[:protocol]
    end

    it 'vertica' do
      subject.instance_eval { db :vertica }
      assert_equal 'vertica', subject.adapter[:protocol]
    end
  end

  describe "#connection_address" do
    it 'sqlite' do
      subject.instance_eval { db :sqlite }
      assert_equal 'sqlite://db/event_store_test.db', subject.connection_url
    end
  end
end
