require 'test_helper'
require 'ttnt/test_selector'

class TestSelectorTest < TTNT::TestCase
  def setup
    target_sha = @repo.branches['change_fizz'].target.oid
    master_sha = @repo.branches['master'].target.oid
    base_sha = @repo.merge_base(target_sha, master_sha)
    @selector = TTNT::TestSelector.new(@repo, target_sha, base_sha)
  end

  def test_base_obj_selection
    # Commit on which `rake ttnt:anchor` is invoked. Not the one `.ttnt` files are committed
    assert_equal @selector.instance_variable_get('@base_obj').oid,
      "bf1931131cf0d01c1a02b8f08085b90c9a92acd4"
  end

  def test_selects_tests
    assert_equal @selector.select_tests.to_a, ['test/fizz_test.rb']
  end
end
