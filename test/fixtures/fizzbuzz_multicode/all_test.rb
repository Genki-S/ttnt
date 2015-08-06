require 'minitest/autorun'
require_relative './fizzbuzz'

class TestAll < Minitest::Test
  def test_all
    fb = FizzBuzz.new
    assert_equal "fizz", fb.convert(3)
    assert_equal "buzz", fb.convert(5)
    assert_equal "fizzbuzz", fb.convert(15)
  end
end
