require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:'spec:ci')

task :default => :'spec:ci'


desc "one-time install for hstore extension in postgres"
task :'db:install_hstore' do
  #http://stackoverflow.com/questions/11584749/how-to-create-a-new-database-with-the-hstore-extension-already-installed
  sh "psql -d template1 -c 'create extension hstore;'"
end

desc "migrate development db"
task :'db:migrate' do
  begin
    sh 'createdb event_store_development'
  rescue => e
    #we don't care if it exists alreay, so don't fail
  end
  sh 'bundle exec sequel -m db/migrations postgres://localhost:5432/event_store_development'
end

desc "migrate test db (drops test db first)"
task :'db:test:prepare' do
  sh 'bundle exec sequel -m db/migrations vertica://dbadmin:password@192.168.180.65:5433/nexia_history'
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