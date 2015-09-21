require 'minitest/autorun'
require_relative './fizzbuzz'

class TestFizz < Minitest::Test
  def test_fizz
    fb = FizzBuzz.new
    assert_equal "fizz", fb.convert(3)
    assert_equal "fizz", fb.convert(6)
    assert_equal "fizz", fb.convert(9)
  end
end
