require_relative '../spec_helper'

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
    expect(config.username).to eq("username")
    expect(config.port).to eq(5555)
    expect(config.password).to eq("password")
    expect(config.host).to eq("host")
    expect(config.database).to eq("database")
  end

  describe '#adapter_settings' do
    it 'sqlite' do
      subject.instance_eval { adapter :sqlite }
      expect(subject.adapter_options[:protocol]).to eq('sqlite')
    end

    it 'postgres' do
      subject.instance_eval { adapter :postgres }
      expect(subject.adapter_options[:protocol]).to eq('postgres')
    end

    it 'vertica' do
      subject.instance_eval { adapter :vertica }
      expect(subject.adapter_options[:protocol]).to eq('vertica')
    end
  end

  describe "#connection_address" do
    it 'sqlite' do
      subject.instance_eval {
        adapter  :sqlite
        database "db/event_store_test.db"
      }
      expect(subject.connection_url).to eq('sqlite://db/event_store_test.db')
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
      expect(subject.connection_url).to eq("postgres://stuart:password1@nexia:5432/test_db")
    end

    it 'leaves out username and password if they arent included' do
      subject.instance_eval {
        adapter :postgres
        host    "nexia"
        port     5432
        database "test_db"
      }
      expect(subject.connection_url).to eq("postgres://nexia:5432/test_db")
    end

    it 'defaults to port 5432' do
      subject.instance_eval {
        adapter :postgres
        host    "nexia"
        database "test_db"
      }
      expect(subject.connection_url).to eq("postgres://nexia:5432/test_db")
    end
  end
end
