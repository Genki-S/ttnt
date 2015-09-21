require 'minitest/autorun'
require_relative './fizzbuzz'

class TestBuzz < Minitest::Test
  def test_buzz
    fb = FizzBuzz.new
    assert_equal "buzz", fb.convert(5)
    assert_equal "buzz", fb.convert(10)
    assert_equal "buzz", fb.convert(20)
  end
end
