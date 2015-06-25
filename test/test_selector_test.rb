require 'test_helper'
require 'ttnt/test_selector'

class TestSelectorTest < TTNT::TestCase
  def setup
    @repo.checkout('change_fizz')
    @selector = TTNT::TestSelector.new(@repo)
  end

  def test_base_obj_selection
    # Commit on which mapping file is committed
    assert_equal @selector.instance_variable_get('@base_obj').oid,
      "0de92248f0a16e27d7b017ff61428163bb136cbc"
  end

  def test_selects_tests
    assert_equal @selector.select_tests.to_a, ['test/fizz_test.rb']
  end
end
