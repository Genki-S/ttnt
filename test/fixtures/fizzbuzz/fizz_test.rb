require 'minitest/autorun'
require_relative './fizzbuzz'

class TestFizz < Minitest::Test
  def test_fizz
    assert_equal "fizz", fizzbuzz_convert(3)
    assert_equal "fizz", fizzbuzz_convert(6)
    assert_equal "fizz", fizzbuzz_convert(9)
  end
end
