require 'test_helper'
require 'ttnt/test_selector'

module TTNT
  class TestSelectorTest < TTNT::TestCase
    def setup
      target_sha = @repo.branches['change_fizz'].target.oid
      master_sha = @repo.branches['master'].target.oid
      @test_files = Rake::FileList['test/**/*_test.rb']
      @selector = TTNT::TestSelector.new(@repo, target_sha, @test_files)
    end

    def test_base_obj_selection
      # Commit on which `rake ttnt:anchor` is invoked. Not the one `.ttnt` files are committed
      assert_equal @selector.instance_variable_get('@base_obj').oid, @anchored_sha
    end

    def test_selects_tests
      assert_equal nil, @selector.tests
      assert_equal ['test/fizz_test.rb'], @selector.select_tests!.to_a
      assert_equal ['test/fizz_test.rb'], @selector.tests.to_a
    end

    def test_selects_tests_with_changed_test_file
      buzz_test = "#{@repo.workdir}/test/buzz_test.rb"
      File.write(buzz_test, File.read(buzz_test) + "\n") # meaningless change
      git_checkout_b('change_buzz_test') # from master
      git_commit_am('Change buzz_test')
      target_sha = @repo.head.target_id
      master_sha = @repo.branches['master'].target.oid
      selector = TTNT::TestSelector.new(@repo, target_sha, @test_files)
      assert_includes selector.select_tests!, 'test/buzz_test.rb'
    end
  end
end
