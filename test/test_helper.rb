unless ENV['ANCHOR_TASK']
  require 'coveralls'
  Coveralls.wear!
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ttnt'
require 'helpers/git_helper'
require 'helpers/rake_helper'

require 'rugged'
require 'minitest/autorun'

module TTNT
  class TestCase < Minitest::Test
    FIXTURE_DIR = File.join(__dir__, 'fixtures')

    include GitHelper
    include RakeHelper

    def before_setup
      super
      prepare_git_repository
      @pwd = Dir.pwd
      Dir.chdir(@repo.workdir)
    end

    def after_teardown
      Dir.chdir(@pwd)
      FileUtils.remove_entry_secure(@tmpdir)
      super
    end

    private

    def prepare_git_repository
      @tmpdir = Dir.mktmpdir('ttnt_repository')
      @repo = Rugged::Repository.init_at(@tmpdir)
      populate_with_fixtures
      load_rakefile("#{@tmpdir}/Rakefile")
      anchor_and_commit
      make_change_fizz_branch
    end

    def populate_with_fixtures
      copy_fixture('Rakefile', "#{@tmpdir}/Rakefile")
      git_commit_am('Add Rakefile')
      copy_fixture('fizzbuzz.rb', "#{@tmpdir}/lib/fizzbuzz.rb")
      git_commit_am('Add fizzbuzz code')
      copy_fixture('fizz_test.rb', "#{@tmpdir}/test/fizz_test.rb")
      copy_fixture('buzz_test.rb', "#{@tmpdir}/test/buzz_test.rb")
      git_commit_am('Add fizzbuzz tests')
    end

    def anchor_and_commit
      @anchored_sha = @repo.head.target_id
      rake('ttnt:test:anchor')
      git_commit_am('Add TTNT generated files')
    end

    def make_change_fizz_branch
      git_checkout_b('change_fizz')
      fizzbuzz_file = "#{@repo.workdir}/lib/fizzbuzz.rb"
      new_content = "\n" * 10 # diff uglifier
      new_content += File.read(fizzbuzz_file).gsub(/"fizz"$/, '"foo"')
      File.write(fizzbuzz_file, new_content)
      git_commit_am('Change fizz code')
      @repo.checkout('master')
    end

    def copy_fixture(src, dest)
      unless File.directory?(File.dirname(dest))
        FileUtils.mkdir_p(File.dirname(dest))
      end
      FileUtils.cp("#{FIXTURE_DIR}/#{src}", dest)
    end

    def capture
      captured_stream     = Tempfile.new("stdout")
      origin_stream       = $stdout.dup
      captured_stream_err = Tempfile.new("stderr")
      origin_stream_err   = $stderr.dup
      $stdout.reopen(captured_stream)
      $stderr.reopen(captured_stream_err)

      yield

      $stdout.rewind
      $stderr.rewind
      return { stdout: captured_stream.read, stderr: captured_stream_err.read }
    ensure
      captured_stream.close
      captured_stream.unlink
      captured_stream_err.close
      captured_stream_err.unlink
      $stdout.reopen(origin_stream)
      $stderr.reopen(origin_stream_err)
    end
  end
end
