require 'sequel'
require 'event_store/errors'

module EventStore
  class Configuration
    attr_reader :adapter_options, :username, :password, :host, :port, :db_name
    def db adapter
      @adapter_options = adapter_settings.fetch(adapter)
      requires
    rescue KeyError
      raise InvalidAdapterError, "The adapter #{adapter} could not be found."
    end

    def requires
      require adapter_options[:requires] if adapter_options[:requires]
    end

    def connect_to_db
      Sequel.connect connection_url
    end

    def credentials credentials
      check_credentials credentials
      credentials.each do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    def check_credentials credentials
      %w{host port db_name}.map(&:to_sym).each do |cred|
        begin
          credentials.fetch cred
        rescue KeyError
          unless adapter_options[:defaults][cred]
            raise MissingCredentialError, "#{cred} is required to configure your adapter."
          end
        end
      end
    end

    def connection_url
      "#{adapter_options[:protocol]}://#{connection_address}"
    end

    def connection_address
      @connection_address ||= "#{login_info}#{location_info}#{db_name}"
    end

    def location_info
      "#{host}:#{ port || adapter_options[:defaults][:port] }/" if host
    end

    def login_info
      "#{username}:#{password}@" if username && password
    end

    def adapter_settings
      {
        sqlite: {
          protocol: "sqlite",
          defaults: {
            host: '',
            port: ''
          }
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
