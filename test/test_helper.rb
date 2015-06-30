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
    FIXTURE_DIR = File.expand_path('../fixtures', __FILE__).freeze

    def before_setup
      super
      prepare_git_repository
    end

    def after_teardown
      FileUtils.remove_entry_secure(@tmpdir)
      super
    end

    private

    def prepare_git_repository
      @tmpdir = Dir.mktmpdir('ttnt_repository')
      @repo = Rugged::Repository.init_at(@tmpdir)
      populate_with_fixtures
      RakeHelper.load_rakefile("#{@tmpdir}/Rakefile")
    end

    def populate_with_fixtures
      copy_fixture('Rakefile', "#{@tmpdir}/Rakefile")
      GitHelper.commit_am(@repo, 'Add Rakefile')
      copy_fixture('fizzbuzz.rb', "#{@tmpdir}/lib/fizzbuzz.rb")
      GitHelper.commit_am(@repo, 'Add fizzbuzz code')
      copy_fixture('fizz_test.rb', "#{@tmpdir}/test/fizz_test.rb")
      copy_fixture('buzz_test.rb', "#{@tmpdir}/test/buzz_test.rb")
      GitHelper.commit_am(@repo, 'Add fizzbuzz tests')
    end

    def copy_fixture(src, dest)
      unless File.directory?(File.dirname(dest))
        FileUtils.mkdir_p(File.dirname(dest))
      end
      FileUtils.cp("#{FIXTURE_DIR}/#{src}", dest)
    end
  end
end
