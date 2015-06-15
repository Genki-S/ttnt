require "bundler/gem_tasks"
require "rake/testtask"
require "ttnt/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
  TTNT::TestTask.new(t)
end

task :default => :test
