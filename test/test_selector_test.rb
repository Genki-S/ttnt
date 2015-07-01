require 'test_helper'
require 'ttnt/test_selector'

module TTNT
  class TestSelectorTest < TTNT::TestCase
    def setup
      @anchored_sha = @repo.head.target_id
      RakeHelper.rake('ttnt:test:anchor', dir: @repo.workdir)
      GitHelper.commit_am(@repo, 'Add TTNT generated files')
      GitHelper.checkout_b(@repo, 'change_fizz')
      fizzbuzz_file = "#{@repo.workdir}/lib/fizzbuzz.rb"
      File.write(fizzbuzz_file, File.read(fizzbuzz_file).gsub(/"fizz"$/, '"foo"'))
      GitHelper.commit_am(@repo, 'Change fizz code')

      target_sha = @repo.branches['change_fizz'].target.oid
      master_sha = @repo.branches['master'].target.oid
      base_sha = @repo.merge_base(target_sha, master_sha)
      @selector = TTNT::TestSelector.new(@repo, target_sha, base_sha)
    end

    def test_base_obj_selection
      # Commit on which `rake ttnt:anchor` is invoked. Not the one `.ttnt` files are committed
      assert_equal @selector.instance_variable_get('@base_obj').oid, @anchored_sha
    end

    def test_selects_tests
      assert_equal @selector.select_tests.to_a, ['test/fizz_test.rb']
    end
  end
end
