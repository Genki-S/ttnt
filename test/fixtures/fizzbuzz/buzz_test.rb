require 'minitest/autorun'
require_relative './fizzbuzz'

class TestBuzz < Minitest::Test
  def test_buzz
    assert_equal "buzz", fizzbuzz_convert(5)
    assert_equal "buzz", fizzbuzz_convert(10)
    assert_equal "buzz", fizzbuzz_convert(20)
  end
end
