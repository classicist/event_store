require_relative '../minitest_helper'

describe EventStore::Configuration do
  subject { EventStore::Configuration.new }
  it 'should set the credentials on the instance' do
    config = EventStore::Configuration.new
    config.instance_eval {
      username "username"
      password "password"
      host     "host"
      port      5555
      database  "database"
    }
    assert_equal "username", config.username
    assert_equal  5555, config.port
    assert_equal "password", config.password
    assert_equal "host", config.host
    assert_equal "database", config.database
  end

  describe '#adapter_settings' do
    it 'sqlite' do
      subject.instance_eval { adapter :sqlite }
      assert_equal 'sqlite', subject.adapter_options[:protocol]
    end

    it 'postgres' do
      subject.instance_eval { adapter :postgres }
      assert_equal 'postgres', subject.adapter_options[:protocol]
    end

    it 'vertica' do
      subject.instance_eval { adapter :vertica }
      assert_equal 'vertica', subject.adapter_options[:protocol]
    end
  end

  describe "#connection_address" do
    it 'sqlite' do
      subject.instance_eval {
        adapter  :sqlite
        database "db/event_store_test.db"
      }
      assert_equal 'sqlite://db/event_store_test.db', subject.connection_url
    end

    it 'postgres' do
      subject.instance_eval {
        adapter  :postgres
        username "stuart"
        password "password1"
        host     "nexia"
        port      5432
        database  "test_db"
      }
      assert_equal "postgres://stuart:password1@nexia:5432/test_db", subject.connection_url
    end

    it 'leaves out username and password if they arent included' do
      subject.instance_eval {
        adapter :postgres
        host    "nexia"
        port     5432
        database "test_db"
      }
      assert_equal "postgres://nexia:5432/test_db", subject.connection_url
    end

    it 'defaults to port 5432' do
      subject.instance_eval {
        adapter :postgres
        host    "nexia"
        database "test_db"
      }
      assert_equal "postgres://nexia:5432/test_db", subject.connection_url
    end
  end
end
