require 'rugged'
require 'colorize'
require 'rake'
require 'ttnt/test_selector'

module TTNT
  # TTNT version of Rake::TestTask.
  # Uses configuration from Rake::TestTask to minimize user configuration.
  # Defines TTNT related rake tasks when instantiated.
  class TestTask
    include Rake::DSL

    GIT_AUTHOR_NAME = 'TTNT Developer'.freeze
    GIT_AUTHOR_EMAIL = 'genki.sugimoto.jp@gmail.com'.freeze

    # An instance of `Rake::TestTask` passed when TTNT::TestTask is initialized
    attr_accessor :rake_testtask

    # Create an instance of TTNT::TestTask and define TTNT rake tasks.
    #
    # @param rake_testtask [Rake::TestTask] an instance of Rake::TestTask after user configuration is done
    def initialize(rake_testtask)
      @rake_testtask = rake_testtask
      # Since test_files is not exposed in Rake::TestTask
      @test_files = @rake_testtask.instance_variable_get('@test_files')

      @anchor_description = 'Generate test-to-code mapping' + (@rake_testtask.name == :test ? '' : " for #{@rake_testtask.name}")
      @run_description = 'Run selected tests' + (@rake_testtask.name == :test ? '' : "for #{@rake_testtask.name}")
      define_tasks
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
        namespace @rake_testtask.name do
          define_run_task
          define_anchor_task
        end
      end
    end

    # Define a task which runs only tests which might have affected from changes
    # in BASE_SHA...TARGET_SHA
    #
    # TARGET_SHA and BASE_SHA can be specified as an environment variable. They
    # defaults to HEAD and merge base between master and TARGET_SHA, respectively.
    #
    # @return [void]
    def define_run_task
      desc @run_description
      task 'run' do
        ts = TTNT::TestSelector.new(repo)
        tests = ts.select_tests
        if tests.empty?
          STDERR.puts 'No test selected.'
        else
          args =
            "#{@rake_testtask.ruby_opts_string} #{@rake_testtask.run_code} " +
            "#{tests.to_a.join(' ')} #{@rake_testtask.option_list}"
          run_ruby args
        end
      end
    end

    # Define a task which runs test files file by file, and generate and save
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

        unless repo.diff_workdir('HEAD').deltas.empty?
          print_dirty_workdir_warning
          exit 1
        end

        Rake::FileUtilsExt.verbose(@rake_testtask.verbose) do
          # Make it possible to require files in this gem
          gem_root = File.expand_path('../..', __FILE__)
          args =
            "-I#{gem_root} -r ttnt/anchor " +
            "#{@rake_testtask.ruby_opts_string}"

          test_files = Rake::FileList[@rake_testtask.pattern].compact
          test_files += @test_files.to_a if @test_files
          test_files.each do |test_file|
            run_ruby "#{args} #{test_file}"
          end
        end

        commit_ttnt_files!
        print_finish_message
      end
    end

    # Run ruby process with given args
    #
    # @param args [String] argument to pass to ruby
    def run_ruby(args)
      ruby "#{args}" do |ok, status|
        if !ok && status.respond_to?(:signaled?) && status.signaled?
          raise SignalException.new(status.termsig)
        elsif !ok
          fail "Command failed with status (#{status.exitstatus}): " +
            "[ruby #{args}]"
        end
      end
    end

    # Create a commit which registers test-to-code mapping file to the repository.
    #
    # @return [void]
    def commit_ttnt_files!
      author = {
        name: GIT_AUTHOR_NAME,
        email: GIT_AUTHOR_EMAIL,
        time: Time.now
      }
      index = repo.index
      index.read_tree(repo.head.target.tree)
      index.add('.ttnt/test_to_code_mapping.json')
      tree = index.write_tree
      Rugged::Commit.create(repo,
                            author: author,
                            message: 'Save TTNT generated files',
                            committer: author,
                            parents: repo.empty? ? [] : [repo.head.target].compact,
                            tree: tree,
                            update_ref: 'HEAD')
    end

    def print_finish_message
      lines = [
        'test-to-code mapping is created and commited to your git repository.',
        'Please note that changing the commit order by rebasing might cause',
        'unexpected behavior afterwards.'
      ].map { |l| l.colorize(:yellow) }
      warn(*lines)
    end

    def print_dirty_workdir_warning
      lines = [
        'You have uncommited changes in your working directory.',
        'This can produce inconsistent data to your test-to-code mapping.',
        "Please commit changes before running `rake ttnt:#{@rake_testtask.name}:anchor`."
      ].map { |l| l.colorize(:red) }
      warn(*lines)
    end
  end
end
