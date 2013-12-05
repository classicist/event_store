require 'sequel'
require 'event_store/errors'

module EventStore
  class Configuration
    attr_accessor :adapter
    def db adapter
      self.adapter = adapter_settings.fetch(adapter)
      requires
      # Sequel::Model.db = adapter
    rescue KeyError
      raise InvalidAdapterError, "The adapter #{adapter} could not be found."
      # now set db method to return Sequel::Model.db
    end
    # Sequel::Model

    def requires
      require adapter[:requires] if adapter[:requires]
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
      %w{username password port db_name}.map(&:to_sym).each do |cred|
        begin
          credentials.fetch cred
        rescue KeyError
          raise MissingCredentialError, "#{cred} is required to configure your adapter."
        end
      end
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
