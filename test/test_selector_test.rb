require 'test_helper'
require 'ttnt/test_selector'

module TTNT
  class TestSelectorTest < TTNT::TestCase::FizzBuzz
    def setup
      target_sha = @repo.branches['change_fizz'].target.oid
      @test_files = Rake::FileList['**/*_test.rb']
      @selector = TTNT::TestSelector.new(@repo, target_sha, @test_files)
    end

    def test_base_obj_selection
      # Commit on which `rake ttnt:anchor` is invoked. Not the one `.ttnt` files are committed
      assert_equal @selector.instance_variable_get('@base_obj').oid, @anchored_sha
    end

    def test_selects_tests
      assert_equal nil, @selector.tests
      assert_equal ['fizz_test.rb'], @selector.select_tests!.to_a
      assert_equal ['fizz_test.rb'], @selector.tests.to_a
    end

    def test_selects_tests_from_current_working_tree
      @repo.checkout('change_fizz')

      # Change buzz too
      fizzbuzz_file = "#{@repo.workdir}/fizzbuzz.rb"
      selector      = TTNT::TestSelector.new(@repo, nil, @test_files)

      File.write(fizzbuzz_file, File.read(fizzbuzz_file).gsub(/"buzz"$/, '"bar"'))

      assert_equal Set.new(['fizz_test.rb', 'buzz_test.rb']), selector.select_tests!
    end

    def test_selects_tests_with_changed_test_file
      buzz_test = "#{@repo.workdir}/buzz_test.rb"

      File.write(buzz_test, File.read(buzz_test) + "\n") # meaningless change

      git_checkout_b('change_buzz_test') # from master
      git_commit_am('Change buzz_test')

      target_sha = @repo.head.target_id
      selector   = TTNT::TestSelector.new(@repo, target_sha, @test_files)

      assert_includes selector.select_tests!, 'buzz_test.rb'
    end

    def test_selects_all_tests_with_no_anchored_commit
      git_rm_and_commit("#{@repo.workdir}/.ttnt", 'Remove .ttnt file')
      selector = TTNT::TestSelector.new(@repo, @repo.head.target_id, @test_files)

      assert_equal Set.new(['fizz_test.rb', 'buzz_test.rb']), selector.select_tests!
    end

    def test_selects_untracked_test_files
      new_test = 'test/new_test.rb'
      selector = TTNT::TestSelector.new(@repo, nil, @test_files)

      FileUtils.mkdir('test')
      FileUtils.touch(new_test)

      assert_equal Set.new([new_test]), selector.select_tests!
    end
  end
end
