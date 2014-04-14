# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'event_store/version'

Gem::Specification.new do |spec|
  spec.name          = "event_store"
  spec.version       = EventStore::VERSION
  spec.authors       = ["Paul Saieg, John Colvin", "Stuart Nelson"]
  spec.description   = ["A Ruby implementation of an EventSource (A+ES) tuned for Vertica or Postgres"]
  spec.email         = ["classicist@gmail.com"]
  spec.summary       = %q{Ruby implementation of an EventSource (A+ES) for the Nexia Ecosystem}
  spec.homepage      = "https://github.com/nexiahome/event_store"
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

  spec.add_dependency "sequel", "~> 4.9.0"
  spec.add_dependency 'sequel-vertica', '~> 0.2.0'
  spec.add_dependency 'pg', '~> 0.17.1'
  spec.add_dependency 'redis', "~> 3.0.7"
  spec.add_dependency 'hiredis'
  spec.add_development_dependency 'rspec_junit_formatter'
end
