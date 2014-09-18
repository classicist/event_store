# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'event_store/version'

Gem::Specification.new do |spec|
  spec.name          = 'nexia_event_store'
  spec.version       = EventStore::VERSION
  spec.authors       = ['Paul Saieg, John Colvin', 'Stuart Nelson']
  spec.description   = ['A Ruby implementation of an EventSource (A+ES) tuned for Vertica or Postgres']
  spec.email         = ['classicist@gmail.com, jgeiger@gmail.com']
  spec.summary       = %q{Ruby implementation of an EventSource (A+ES) for the Nexia Ecosystem}
  spec.homepage      = 'https://github.com/nexiahome/event_store'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_development_dependency 'simplecov-rcov', '~> 0.2'
  spec.add_development_dependency 'guard-rspec', '~> 4.3'
  spec.add_development_dependency 'pry-byebug', '~> 2.0'
  spec.add_development_dependency 'mock_redis', '~> 0.13'

  spec.add_dependency 'sequel', '~> 4.14'
  spec.add_dependency 'nexia-sequel-vertica', '~> 0.2'
  spec.add_dependency 'pg', '~> 0.17'
  spec.add_dependency 'redis', '~> 3.1'
  spec.add_dependency 'hiredis', '~> 0.5'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2'
end
