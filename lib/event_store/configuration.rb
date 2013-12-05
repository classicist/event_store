require 'sequel'
require 'event_store/errors'

module EventStore
  class Configuration
    attr_accessor :adapter
    attr_reader :get_db
    def db adapter
      self.adapter = adapter_settings.fetch(adapter)
      requires
      @connection_address = "db/event_store_test.db" if adapter == :sqlite
    rescue KeyError
      raise InvalidAdapterError, "The adapter #{adapter} could not be found."
    end

    def requires
      require adapter[:requires] if adapter[:requires]
    end

    def set_db
      @get_db = Sequel.connect connection_url
    end

    def credentials credentials
      check_credentials credentials
      credentials.each do |k,v|
        self.class.instance_eval do
          attr_reader k
        end
        instance_variable_set("@#{k}", v)
      end
    end

    def check_credentials credentials
      %w{username password host port db_name}.map(&:to_sym).each do |cred|
        begin
          credentials.fetch cred
        rescue KeyError
          raise MissingCredentialError, "#{cred} is required to configure your adapter."
        end
      end
    end

    def connection_url
      "#{adapter[:protocol]}://#{connection_address}"
    end

    def connection_address
      @connection_address ||= "#{username}:#{password}@#{host}:#{port}/#{db_name}"
    end

    def adapter_settings
      {
        sqlite: {
          protocol: "sqlite"
        },
        postgres: {
          protocol: "postgres"
        },
        vertica: {
          protocol: "vertica",
          requires: "sequel-vertica"
        }
      }
    end
  end
end
