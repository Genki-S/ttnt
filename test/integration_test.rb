require 'test_helper'
require 'ttnt/test_to_code_mapping'

module TTNT
  class IntegrationTest < TTNT::TestCase
    def test_saving_anchored_commit
      anchored_commit = @repo.head.target_id
      rake('ttnt:test:anchor')
      metadata = TTNT::MetaData.new(@repo)
      assert_equal anchored_commit, metadata['anchored_commit']
    end

    def test_mapping_generation
      mapping = TTNT::TestToCodeMapping.new(@repo, @repo.head.target_id).read_mapping
      expected_mapping = {"test/buzz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 6, 7]},
                          "test/fizz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 5]}}
      assert_equal expected_mapping, mapping
    end

    def test_no_test_is_selected
      output = rake('ttnt:test:run')
      assert_equal "", output[:stdout]
    end

    def test_fizz_test_is_selected
      @repo.checkout('change_fizz')
      output = rake('ttnt:test:run')
      assert_match '1 runs, 1 assertions, 1 failures', output[:stdout]
    end
  end
end
