require 'test_helper'
require 'ttnt/test_to_code_mapping'

class TestToCodeMappingTest < TTNT::TestCase::FizzBuzz
  def setup
    # clean up generated .ttnt files
    File.delete("#{@repo.workdir}/.ttnt")
    @test_to_code_mapping = TTNT::TestToCodeMapping.new(@repo)
    @test_file = 'fizz_test.rb'
    # Not a valid coverage, but an example
    @coverage = { "#{@repo.workdir}/fizzbuzz.rb"=> [1, 1, nil, 1, 0, 1, 0, 1, 0] }
    @test_to_code_mapping.append_from_coverage(@test_file, @coverage)
  end

  def test_append_from_coverage
    expected_mapping = {
      @test_file => { 'fizzbuzz.rb' => [1, 2, 4, 6, 8] }
    }
    assert_equal expected_mapping, @test_to_code_mapping.mapping
  end

  def test_get_tests
    assert_equal Set.new([@test_file]),
      @test_to_code_mapping.get_tests(file: 'fizzbuzz.rb', lineno: 3),
      'It should select tests if the specified line is between the topmost executed line and downmost executed line in coverage'
    assert_equal Set.new([]),
      @test_to_code_mapping.get_tests(file: 'fizzbuzz.rb', lineno: 9),
      'It should not select tests if the specified line is not between the topmost executed line and downmost executed line in coverage'
    assert_equal Set.new([@test_file]),
      @test_to_code_mapping.get_tests(file: 'fizzbuzz.rb', lineno: 2)
  end
end
