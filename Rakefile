require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Run sequel migrations"
task :'db:migrate:sqlite' do
  sh 'bundle exec sequel -m db/migrations sqlite://db/event_store_test.db'
end

task :'db:migrate:pg' do
  begin
    sh 'createdb nexia_event_store_development'
  rescue => e
    #we don't care if it exists alreay, so don't fail
  end
  sh 'bundle exec sequel -m db/migrations postgres://localhost:5432/nexia_event_store_development'
end

task :'db:migrate:pg_perf' do
  begin
    sh 'createdb event_store_performance'
  rescue => e
    #we don't care if it exists alreay, so don't fail
  end
  sh 'bundle exec sequel -m db/migrations postgres://localhost:5432/event_store_performance'
end