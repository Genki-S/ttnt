require 'rake/testtask'
require 'rake/file_list'
require 'ttnt/testtask'
require 'ttnt/test_selector'
require 'rugged'

# Reference: https://github.com/bundler/bundler/blob/master/lib/bundler/gem_helper.rb
module TTNT
  class TaskHelper
    include Rake::DSL

    def self.install_tasks
      new.install
    end

    def install
      namespace :ttnt do
        desc 'Generate test-to-code mapping for current commit object'
        task 'anchor' do
          # TODO: what if multiple test tasks are defined?
          test_task = TTNT::TestTask.instances.first
          test_files = []
          test_files += test_task.test_files.to_a if test_task.test_files
          test_files += Rake::FileList[test_task.pattern] if test_task.pattern

          # TODO: properly regard run options defined for Rake::TestTask
          gem_root = File.expand_path('..', File.dirname(File.expand_path(__FILE__)))
          args = "-I#{gem_root} -r ttnt/anchor"
          args += " -I#{test_task.libs.join(':')}" unless test_task.libs.empty?
          test_files.each do |test_file|
            ruby "#{args} #{test_file}"
          end
        end

        desc 'Run only tests related to changes in TARGET_SHA (defaults to HEAD) against BASE_SHA (defaults to merge base against master)'
        task 'test' do
          repo = Rugged::Repository.discover('.')
          target_sha = ENV['TARGET_SHA'] || repo.head.target_id
          base_sha = ENV['BASE_SHA'] || repo.merge_base(target_sha, repo.rev_parse('master'))
          ts = TTNT::TestSelector.new(repo, target_sha, base_sha)
          tests = ts.select_tests
          if tests.empty?
            STDERR.puts 'No test selected.'
          else
            # TODO: actually run tests
            tests.each do |test|
              puts test
            end
          end
        end
      end
    end
  end
end

TTNT::TaskHelper.install_tasks
