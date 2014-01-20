require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Run sequel migrations"
task :'db:migrate:sqlite' do
  sh 'bundle exec sequel -m db/migrations sqlite://db/event_store_test.db'
end

task :'db:install_hstore' do
  #http://stackoverflow.com/questions/11584749/how-to-create-a-new-database-with-the-hstore-extension-already-installed
  sh "psql -d template1 -c 'create extension hstore;'"
end

task :'db:migrate:pg' do
  begin
    sh 'dropdb nexia_event_store_development'
    sh 'createdb nexia_event_store_development'
  rescue => e
    #we don't care if it exists alreay, so don't fail
  end
  sh 'bundle exec sequel -m db/migrations postgres://localhost:5432/nexia_event_store_development'
end

task :'db:migrate:pg_perf' do
  begin
    sh 'dropdb event_store_performance'
    sh 'createdb event_store_performance'
  rescue => e
    #we don't care if it exists alreay, so don't fail
  end
  sh 'bundle exec sequel -m db/migrations postgres://localhost:5432/event_store_performance'
end

task :'db:seed:pg_perf' do
  sh 'time bundle exec ruby spec/benchmark/seed_db.rb'
end

task :benchmark do
  sh 'bundle exec ruby spec/benchmark/bench.rb'
end