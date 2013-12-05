module EventStore
  class MissingCredentialError < StandardError; end
  class InvalidAdapterError < StandardError; end
  class ConcurrencyError < StandardError; end
end
