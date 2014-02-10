# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'event_store/version'

Gem::Specification.new do |spec|
  spec.name          = "event_store"
  spec.version       = EventStore::VERSION
  spec.authors       = ["Paul Saieg, John Colvin", "Stuart Nelson"]
  spec.description   = ["A Ruby implementation of an EventSource (A+ES) tuned for Vertica"]
  spec.email         = ["classicist@gmail.com"]
  spec.summary       = %q{Ruby implementation of an EventSource (A+ES) for the Nexia Ecosystem}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-rcov"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry-debugger"
  spec.add_development_dependency "mock_redis"
  spec.add_development_dependency 'sqlite3'

  spec.add_dependency "sequel", "~> 3.42"
  spec.add_dependency 'sequel-vertica', '~> 0.1.0'
  spec.add_dependency 'redis', "~> 3.0.7"
end
