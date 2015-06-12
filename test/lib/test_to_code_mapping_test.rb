require 'test_helper'
require 'ttnt/test_to_code_mapping'

# FIXME: Currently this is working like integration test (using `ttnt-anchor` executable)
class TestToCodeMappingTest < Minitest::Test
  FIZZBUZZ_FIXTURE_DIR = File.expand_path('../../fixtures/repositories/fizzbuzz', __FILE__).freeze

  def setup
    prepare_git_repository
  end

  def teardown
    FileUtils.remove_entry_secure(@tmpdir)
  end

  def test_mapping_generation
    generate_test_to_code_mapping
    Dir.chdir(@repodir) do
      commit_info = File.read('.ttnt/commit_obj.txt')
      assert_equal commit_info, @repo.head.target_id
      mapping = JSON.parse(File.read('.ttnt/test_to_code_mapping.json'))
      expected_mapping = {"test/buzz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 6, 7]},
                          "test/fizz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 5]},
                          "test/fizzbuzz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 3]},
                          "test/non_fizzbuzz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 6, 9]}}
      assert_equal expected_mapping, mapping
    end
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

  def generate_test_to_code_mapping
    anchor_exe = File.expand_path('../../../exe/ttnt-anchor', __FILE__)
    Dir.chdir(@repodir) do
      # Use ttnt-anchor executable from this gem
      Dir.glob('test/*_test.rb').each do |test|
        system("#{anchor_exe} #{test} > /dev/null")
      end
    end
  end
end
