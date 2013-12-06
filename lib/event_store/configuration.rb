require 'sequel'
require 'event_store/errors'

module EventStore
  class Configuration
    attr_reader :adapter_options
    def adapter adapter_name
      @adapter_options = adapter_settings.fetch(adapter_name)
      requires
    rescue KeyError
      raise InvalidAdapterError, "The adapter #{adapter_name} could not be found."
    end

    [:username, :password, :host, :port, :database].each do |meth|
      define_method meth do |*args|
        if args.empty?
          instance_variable_get("@#{meth}")
        else
          instance_variable_set("@#{meth}", args.pop)
        end
      end
    end

    def connect_to_db
      Sequel.connect connection_url
    end

    def connection_url
      "#{adapter_options[:protocol]}://#{connection_address}"
    end

    private
    def requires
      require adapter_options[:requires] if adapter_options[:requires]
    end

    def connection_address
      @connection_address ||= "#{login_info}#{location_info}#{database}"
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
