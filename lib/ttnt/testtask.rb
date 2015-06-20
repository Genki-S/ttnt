require 'rugged'
require 'rake'
require 'ttnt/test_selector'

module TTNT
  class TestTask
    include Rake::DSL

    def initialize(rake_test_task)
      attributes = rake_test_task.instance_variables
      attributes.map! { |attribute| attribute[1..-1] }

      attributes.each do |ivar|
        self.class.class_eval("attr_accessor :#{ivar}")
        if rake_test_task.respond_to?(ivar)
          send(:"#{ivar}=", rake_test_task.send(:"#{ivar}"))
        end
      end
      # Since test_files is not exposed in Rake::TestTask
      @test_files = rake_test_task.instance_variable_get('@test_files')

      @anchor_description = 'Generate test-to-code mapping' + (@name == :test ? '' : " for #{@name}")
      @run_description = 'Run selected tests' + (@name == :test ? '' : "for #{@name}")
      define_tasks
    end

    def repo
      @repo ||= Rugged::Repository.discover('.')
    end

    # Task definitions are taken from Rake::TestTask
    # https://github.com/ruby/rake/blob/e644af3/lib/rake/testtask.rb#L98-L112
    def define_tasks
      namespace :ttnt do
        namespace @name do
          define_run_task
          define_anchor_task
        end
      end
    end

    def define_run_task
      desc @run_description
      task 'run' do
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

    def define_anchor_task
      desc @anchor_description
      task 'anchor' do
        Rake::FileUtilsExt.verbose(@verbose) do
          # Make it possible to require files in this gem
          gem_root = File.expand_path('../..', __FILE__)
          args = "-I#{gem_root}"

          # TODO: properly regard run options defined for Rake::TestTask
          args += " -I#{@libs.join(':')} -r ttnt/anchor"

          test_files = Rake::FileList[@pattern].compact
          test_files += @test_files.to_a if @test_files
          test_files.each do |test_file|
            ruby "#{args} #{test_file}" do |ok, status|
              if !ok && status.respond_to?(:signaled?) && status.signaled?
                raise SignalException.new(status.termsig)
              elsif !ok
                fail "Command failed with status (#{status.exitstatus}): " +
                  "[ruby #{args}]"
              end
            end
          end
        end
      end
    end
  end
end
