require "bundler/gem_tasks"

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib/event_store'
  t.test_files = FileList['test/event_store/*_test.rb']
  t.verbose = true
end

task :default => :test
