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
      %w{host port db_name}.map(&:to_sym).each do |cred|
        begin
          credentials.fetch cred
        rescue KeyError
          unless adapter[:defaults][cred]
            raise MissingCredentialError, "#{cred} is required to configure your adapter."
          end
        end
      end
    end

    def connection_url
      "#{adapter[:protocol]}://#{connection_address}"
    end

    def connection_address
      @connection_address ||=
        "#{login_info}#{host}:#{port||adapter[:defaults][:port]}/#{db_name}"
    end

    def login_info
      "#{username}:#{password}@" if username && password
    end

    def adapter_settings
      {
        sqlite: {
          protocol: "sqlite",
          defaults: {}
        },
        postgres: {
          protocol: "postgres",
          defaults: {
            port: 5432
          }
        },
        vertica: {
          protocol: "vertica",
          requires: "sequel-vertica",
          defaults: {}
        }
      }
    end
  end
end
