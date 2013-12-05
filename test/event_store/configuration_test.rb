require_relative '../minitest_helper'

describe EventStore::Configuration do
  it 'should set the credentials on the instance' do
    config = EventStore::Configuration.new
    config.instance_eval {
      credentials username: "username", password: "password", port: "port", db_name: "db_name"
    }
    assert_equal "username", config.username
    assert_equal "port", config.port
  end

  describe '#adapter_settings' do
    subject { EventStore::Configuration.new }
    it 'sqlite' do
      subject.instance_eval {
        db :sqlite
      }
      assert_equal 'sqlite', subject.adapter[:protocol]
    end

    it 'postgres' do
      subject.instance_eval {
        db :postgres
      }
      assert_equal 'postgres', subject.adapter[:protocol]
    end

    it 'vertica' do
      subject.instance_eval {
        db :vertica
      }
      assert_equal 'vertica', subject.adapter[:protocol]
    end
  end
end
