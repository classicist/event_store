require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:'spec:ci')

task :default => :'spec:ci'

desc "migrate development db"
task :'db:migrate' do
  begin
    sh 'createdb nexia_history'
  rescue => e
    #we don't care if it exists alreay, so don't fail
  end
  sh 'bundle exec sequel -m db/pg_migrations postgres://localhost:5432/nexia_history'
end

desc "migrate test db"
task :'db:test:prepare' do
  begin
    sh 'createdb nexia_history_test'
  rescue => e
    #we don't care if it exists alreay, so don't fail
  end
  sh 'bundle exec sequel -m db/pg_migrations postgres://localhost:5432/nexia_history_test'
end

desc "migrate performance db"
task :'db:migrate:perf' do
  begin
    sh 'dropdb event_store_performance'
    sh 'createdb event_store_performance'
  rescue => e
    #we don't care if it exists alreay, so don't fail
  end
  sh 'bundle exec sequel -m db/migrations postgres://localhost:5432/event_store_performance'
end

desc "Seed the performance db with millions of events"
task :'db:seed:perf' do
  sh 'time bundle exec ruby spec/benchmark/seed_db.rb'
end

desc "Run the performance benchmarks on the performance db"
task :benchmark do
  sh 'bundle exec ruby spec/benchmark/bench.rb'
end