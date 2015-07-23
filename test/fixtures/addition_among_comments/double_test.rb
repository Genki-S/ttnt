require 'minitest/autorun'
require_relative './double'

class TestFizz < Minitest::Test
  def test_double
    assert_equal 4, double(2)
  end
end
