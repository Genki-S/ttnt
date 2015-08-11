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
        expected_mapping = {"buzz_test.rb"=>{"fizzbuzz.rb"=>[2, 3, 5, 6]},
                            "fizz_test.rb"=>{"fizzbuzz.rb"=>[2, 3, 5, 7, 8]}}
        assert_equal expected_mapping, mapping
      end

      def test_no_test_is_selected
        output = rake('ttnt:test:run')
        assert_equal "", output[:stdout]
      end

      def test_all_tests_are_selected_without_mapping
        git_rm_and_commit("#{@repo.workdir}/.ttnt", 'Remove .ttnt')
        rake_ttnt_result = rake('ttnt:test:run')[:stdout].lines.last
        rake_test_result = rake('test')[:stdout].lines.last
        assert_equal rake_test_result, rake_ttnt_result
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

      def test_isolated
        # Make TTNT select all tests
        git_rm_and_commit("#{@repo.workdir}/.ttnt", 'Remove .ttnt')
        ENV['ISOLATED'] = '1'
        output = rake('ttnt:test:run')
        assert_equal 3, output[:stdout].split('# Running:').count
      ensure
        ENV.delete('ISOLATED')
      end

      def test_isolated_with_fail_fast
        @repo.checkout('change_fizz')
        fizzbuzz_file = "#{@repo.workdir}/fizzbuzz.rb"
        File.write(fizzbuzz_file, File.read(fizzbuzz_file).gsub(/"buzz"$/, '"bar"'))
        ENV['ISOLATED'] = '1'
        ENV['FAIL_FAST'] = '1'
        output = rake('ttnt:test:run')
        assert_equal 2, output[:stdout].split('Failure:').count
      ensure
        ENV.delete('ISOLATED')
        ENV.delete('FAIL_FAST')
      end

      def test_select_untracked_files
        FileUtils.mkdir('test')
        fizz_test = './fizz_test.rb'
        File.write(fizz_test, File.read(fizz_test).gsub("require_relative '\.", "require_relative '.."))
        FileUtils.mv('./fizz_test.rb', './test/fizz_test.rb')
        output = rake('ttnt:test:run')
        assert_match '1 runs, 3 assertions, 0 failures', output[:stdout]
      end
    end

    class AdditionAmongComments < TTNT::TestCase::AdditionAmongComments
      def test_selecting_test_even_though_addition_is_made_among_comments
        double_file = "double.rb"
        File.write(double_file, File.read(double_file).gsub(/# ipsum$/, 'n *= 2'))
        output = rake('ttnt:test:run')
        assert_match '1 runs, 1 assertions, 1 failures', output[:stdout]
      end
    end
  end
end
