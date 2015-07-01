require 'test_helper'
require 'ttnt/test_to_code_mapping'

module TTNT
  class IntegrationTest < TTNT::TestCase
    def test_saving_anchored_commit
      anchored_sha = @repo.head.target_id
      RakeHelper.rake('ttnt:test:anchor', dir: @repo.workdir)
      saved = File.read("#{@repo.workdir}/.ttnt/commit_obj.txt")
      assert_equal anchored_sha, saved
    end

    def test_mapping_generation
      mapping = JSON.parse(File.read("#{@repo.workdir}/.ttnt/test_to_code_mapping.json"))
      expected_mapping = {"test/buzz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 6, 7]},
                          "test/fizz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 5]}}
      assert_equal expected_mapping, mapping
    end

    def test_no_test_is_selected
      output = RakeHelper.rake('ttnt:test:run', dir: @repo.workdir)
      assert_equal "", output[:stdout]
    end

    def test_fizz_test_is_selected
      @repo.checkout('change_fizz')
      output = RakeHelper.rake('ttnt:test:run', dir: @repo.workdir)
      assert_match '1 runs, 1 assertions, 1 failures', output[:stdout]
    end
  end
end
