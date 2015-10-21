require 'rugged'
require 'rake/testtask'
require 'ttnt/test_selector'

module TTNT
  # TTNT version of Rake::TestTask.
  #
  # You can use the configuration from a Rake::TestTask to minimize user
  # configuration.
  #
  # Defines TTNT related rake tasks when instantiated.
  class TestTask
    include Rake::DSL

    attr_accessor :rake_testtask
    attr_reader   :code_files, :test_files

    # Create an instance of TTNT::TestTask and define TTNT rake tasks.
    #
    # @param rake_testtask [Rake::TestTask] an instance of Rake::TestTask
    #   after user configuration is done
    def initialize(rake_testtask = nil)
      @rake_testtask = rake_testtask || Rake::TestTask.new

      # There's no `test_files` method so we can't delegate it
      # to the internal task through `method_missing`.
      @test_files = @rake_testtask.instance_variable_get('@test_files')

      yield self if block_given?

      target = (name == :test) ? '' : " for #{name}"
      @anchor_description = "Generate test-to-code mapping#{target}"
      @run_description = "Run selected tests#{target}"
      define_tasks
    end

    # Delegate missing methods to the internal task
    # so we can override the defaults during the
    # block execution.
    def method_missing(method, *args, &block)
      @rake_testtask.public_send(method, *args, &block)
    end

    def code_files=(files)
      @code_files = files.kind_of?(String) ? FileList[files] : files
    end

    def test_files=(files)
      @test_files = files.kind_of?(String) ? FileList[files] : files
    end

    # Returns array of test file names.
    #   Unlike Rake::TestTask#file_list, patterns are expanded.
    def expanded_file_list
      test_files = Rake::FileList[pattern].compact
      test_files += @test_files.to_a if @test_files
      test_files
    end

    private

    # Git repository discovered from current directory
    #
    # @return [Rugged::Reposiotry]
    def repo
      @repo ||= Rugged::Repository.discover('.')
    end

    # Define TTNT tasks under namespace 'ttnt:TESTNAME'
    #
    # @return [void]
    def define_tasks
      # Task definitions are taken from Rake::TestTask
      # https://github.com/ruby/rake/blob/e644af3/lib/rake/testtask.rb#L98-L112
      namespace :ttnt do
        namespace name do
          define_run_task
          define_anchor_task
        end
      end
    end

    # Define a task which runs only tests which might have been affected from
    # changes between anchored commit and TARGET_SHA.
    #
    # TARGET_SHA can be specified as an environment variable (defaults to HEAD).
    #
    # @return [void]
    def define_run_task
      desc @run_description
      task 'run' do
        target_sha = ENV['TARGET_SHA']
        ts = TTNT::TestSelector.new(repo, target_sha, expanded_file_list)
        tests = ts.select_tests!

        if tests.empty?
          STDERR.puts 'No test selected.'
        else
          if ENV['ISOLATED']
            tests.each do |test|
              args = "#{ruby_opts_string} #{test} #{option_list}"
              run_ruby args
              break if @failed && ENV['FAIL_FAST']
            end
          else
            args =
              "#{ruby_opts_string} #{run_code} " +
              "#{tests.to_a.join(' ')} #{option_list}"
            run_ruby args
          end
        end
      end
    end

    # Define a task which runs tests file by file, and generate and save
    # test-to-code mapping.
    #
    # @return [void]
    def define_anchor_task
      desc @anchor_description
      task 'anchor' do
        # In order to make it possible to stop coverage services like Coveralls
        # which interferes with ttnt/anchor because both use coverage library.
        # See test/test_helper.rb
        ENV['ANCHOR_TASK'] = '1'

        Rake::FileUtilsExt.verbose(verbose) do
          # Make it possible to require files in this gem
          gem_root = File.expand_path('../..', __FILE__)
          args =
            "-I#{gem_root} -r ttnt/anchor " +
            "#{ruby_opts_string}"

          expanded_file_list.each do |test_file|
            run_ruby "#{args} #{test_file}"
          end
        end

        if @code_files
          mapping = TestToCodeMapping.new(repo)
          mapping.select_code_files!(@code_files)
          mapping.write!
        end
      end
    end

    # Run ruby process with given args
    #
    # @param args [String] argument to pass to ruby
    def run_ruby(args)
      ruby "#{args}" do |ok, status|
        @failed = true if !ok
        if !ok && status.respond_to?(:signaled?) && status.signaled?
          raise SignalException.new(status.termsig)
        end
      end
    end
  end
end
