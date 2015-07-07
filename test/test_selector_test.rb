require 'test_helper'
require 'ttnt/test_selector'

module TTNT
  class TestSelectorTest < TTNT::TestCase
    def setup
      target_sha = @repo.branches['change_fizz'].target.oid
      master_sha = @repo.branches['master'].target.oid
      base_sha = @repo.merge_base(target_sha, master_sha)
      @test_files = Rake::FileList['test/**/*_test.rb']
      @selector = TTNT::TestSelector.new(@repo, target_sha, base_sha, @test_files)
    end

    def test_base_obj_selection
      # Commit on which `rake ttnt:anchor` is invoked. Not the one `.ttnt` files are committed
      assert_equal @selector.instance_variable_get('@base_obj').oid, @anchored_sha
    end

    def test_selects_tests
      assert_equal @selector.tests, nil
      assert_equal @selector.select_tests!.to_a, ['test/fizz_test.rb']
      assert_equal @selector.tests.to_a, ['test/fizz_test.rb']
    end

    def test_selects_tests_with_changed_test_file
      buzz_test = "#{@repo.workdir}/test/buzz_test.rb"
      File.write(buzz_test, File.read(buzz_test) + "\n") # meaningless change
      git_checkout_b('change_buzz_test') # from master
      git_commit_am('Change buzz_test')
      target_sha = @repo.head.target_id
      master_sha = @repo.branches['master'].target.oid
      base_sha = @repo.merge_base(target_sha, master_sha)
      selector = TTNT::TestSelector.new(@repo, target_sha, base_sha, @test_files)
      assert_includes selector.select_tests!, 'test/buzz_test.rb'
    end
  end
end
