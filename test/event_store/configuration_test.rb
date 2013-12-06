require 'minitest/autorun'
require 'minitest/pride'
require 'minitest'
require 'event_store'

describe EventStore::Configuration do
  subject { EventStore::Configuration.new }
  it 'should set the credentials on the instance' do
    config = EventStore::Configuration.new
    config.instance_eval {
      username "username"
      password "password"
      host "host"
      port "port"
      db_name "db_name"
    }
    assert_equal "username", config.username
    assert_equal "port", config.port
    assert_equal "password", config.password
    assert_equal "host", config.host
    assert_equal "db_name", config.db_name
  end

  describe '#adapter_settings' do
    it 'sqlite' do
      subject.instance_eval { db :sqlite }
      assert_equal 'sqlite', subject.adapter_options[:protocol]
    end

    it 'postgres' do
      subject.instance_eval { db :postgres }
      assert_equal 'postgres', subject.adapter_options[:protocol]
    end

    it 'vertica' do
      subject.instance_eval { db :vertica }
      assert_equal 'vertica', subject.adapter_options[:protocol]
    end
  end

  describe "#connection_address" do
    it 'sqlite' do
      subject.instance_eval {
        db :sqlite
        db_name "db/event_store_test.db"
      }
      assert_equal 'sqlite://db/event_store_test.db', subject.connection_url
    end

    it 'postgres' do
      subject.instance_eval {
        db :postgres
        username "stuart"
        password "password1"
        host "nexia"
        port "5432"
        db_name "test_db"
      }
      assert_equal "postgres://stuart:password1@nexia:5432/test_db", subject.connection_url
    end

    it 'leaves out username and password if they arent included' do
      subject.instance_eval {
        db :postgres
        host "nexia"
        port "5432"
        db_name "test_db"
      }
      assert_equal "postgres://nexia:5432/test_db", subject.connection_url
    end

    it 'defaults to port 5432' do
      subject.instance_eval {
        db :postgres
        host "nexia"
        db_name "test_db"
      }
      assert_equal "postgres://nexia:5432/test_db", subject.connection_url
    end
  end
end
