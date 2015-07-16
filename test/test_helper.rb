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
  module TestCase
    class Base < Minitest::Test
      include GitHelper
      include RakeHelper

      def fixture_dir
        raise '`fixture_dir` method is not implemented.'
      end

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
        after_preparing_git_repository
      end

      def populate_with_fixtures
        Dir.entries(fixture_dir).each do |file|
          next if file.start_with?('.')
          copy_fixture(file, "#{@tmpdir}/#{file}")
          git_commit_am("Add #{file}")
        end
      end

      def anchor_and_commit
        @anchored_sha = @repo.head.target_id
        rake('ttnt:test:anchor')
        git_commit_am('Add TTNT generated files')
      end

      def copy_fixture(src, dest)
        unless File.directory?(File.dirname(dest))
          FileUtils.mkdir_p(File.dirname(dest))
        end
        FileUtils.cp("#{fixture_dir}/#{src}", dest)
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

    class FizzBuzz < Base
      def fixture_dir
        File.join(__dir__, 'fixtures/fizzbuzz')
      end

      private

      def after_preparing_git_repository
        make_change_fizz_branch
      end

      def make_change_fizz_branch
        git_checkout_b('change_fizz')
        fizzbuzz_file = "#{@repo.workdir}/fizzbuzz.rb"
        new_content = File.read(fizzbuzz_file)
                          .gsub(/"fizzbuzz"$/, '"fizzbizz"' + "\n" * 10) # diff uglifier
                          .gsub(/"fizz"$/, '"foo"')
        File.write(fizzbuzz_file, new_content)
        git_commit_am('Change fizz code')
        @repo.checkout('master')
      end
    end
  end
end
