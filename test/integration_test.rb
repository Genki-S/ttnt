require 'test_helper'
require 'ttnt/test_to_code_mapping'

module TTNT
  module IntegrationTest
    class FizzBuzz < TTNT::TestCase::FizzBuzz
      def test_saving_anchored_commit
        anchored_commit = @repo.head.target_id
        rake('ttnt:test:anchor')
        metadata = TTNT::MetaData.new(@repo)
        assert_equal anchored_commit, metadata['anchored_commit']
      end

      def test_mapping_generation
        mapping = TTNT::TestToCodeMapping.new(@repo, @repo.head.target_id).mapping
        expected_mapping = {"buzz_test.rb"=>{"fizzbuzz.rb"=>[1, 2, 4, 6, 7]},
                            "fizz_test.rb"=>{"fizzbuzz.rb"=>[1, 2, 4, 5]}}
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

      def test_tests_are_selected_based_on_changes_in_current_working_tree
        @repo.checkout('change_fizz')
        # Change buzz too
        fizzbuzz_file = "#{@repo.workdir}/fizzbuzz.rb"
        File.write(fizzbuzz_file, File.read(fizzbuzz_file).gsub(/"buzz"$/, '"bar"'))
        output = rake('ttnt:test:run')
        assert_match '2 runs, 2 assertions, 2 failures', output[:stdout]
      end
    end
  end
end
