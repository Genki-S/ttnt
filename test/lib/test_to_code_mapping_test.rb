require 'test_helper'
require 'ttnt/test_to_code_mapping'

class TestToCodeMappingTest < Minitest::Test
  FIZZBUZZ_FIXTURE_DIR = File.expand_path('../../fixtures/repositories/fizzbuzz', __FILE__).freeze

  def setup
    prepare_git_repository
    @test_to_code_mapping = TTNT::TestToCodeMapping.new(@repo, @repo.head.target_id)
  end

  def teardown
    FileUtils.remove_entry_secure(@tmpdir)
  end

  def test_append_from_coverage
    test_file = 'test/fizz_test.rb'
    # Not a valid coverage, but an example
    coverage = { "#{@repo.workdir}/lib/fizzbuzz.rb"=> [1, 1, nil, 1, 0, 1, 0, 1] }
    @test_to_code_mapping.append_from_coverage(test_file, coverage)
    expected_mapping = {
      test_file => { 'lib/fizzbuzz.rb' => [1, 2, 4, 6, 8] }
    }
    assert_equal expected_mapping, @test_to_code_mapping.read_mapping
  end

  def test_save_commit_info
    @test_to_code_mapping.save_commit_info(@repo.head.target_id)
    assert_equal @repo.head.target_id, File.read("#{@repo.workdir}/.ttnt/commit_obj.txt")
  end

  def test_get_tests
    test_file = 'test/fizz_test.rb'
    coverage = { "#{@repo.workdir}/lib/fizzbuzz.rb"=> [1, 1, nil, 1, 0, 1, 0, 1] }
    @test_to_code_mapping.append_from_coverage(test_file, coverage)
    assert @test_to_code_mapping.get_tests(file: 'lib/fizzbuzz.rb', lineno: 3).empty?,
      'It should be empty for code which is not executed'
    assert_equal Set.new([test_file]),
      @test_to_code_mapping.get_tests(file: 'lib/fizzbuzz.rb', lineno: 2)
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
