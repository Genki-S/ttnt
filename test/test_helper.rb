$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ttnt'

require 'minitest/autorun'

module TTNT
  class TestCase < Minitest::Test
    FIZZBUZZ_FIXTURE_DIR = File.expand_path('../fixtures/repositories/fizzbuzz', __FILE__).freeze

    def setup
      prepare_git_repository
    end

    def teardown
      FileUtils.remove_entry_secure(@tmpdir)
    end

    private

    def prepare_git_repository
      @tmpdir = Dir.mktmpdir('ttnt_repo')
      FileUtils.cp_r(FIZZBUZZ_FIXTURE_DIR, @tmpdir)
      @repodir = "#{@tmpdir}/fizzbuzz"
      Dir.chdir(@repodir) do
        FileUtils.rm('.git')
        File.rename('.gitted', '.git') if File.exist?(".gitted")
      end
      @repo = Rugged::Repository.new(@repodir)
    end
  end
end
