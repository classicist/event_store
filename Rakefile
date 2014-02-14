require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:'spec:ci')

task :default => :'spec:ci'

desc "Seed the performance db with millions of events"
task :'db:seed:perf' do
  sh 'time bundle exec ruby spec/benchmark/seed_db.rb'
end

desc "Run the performance benchmarks on the performance db"
task :benchmark do
  sh 'bundle exec ruby spec/benchmark/bench.rb'
end