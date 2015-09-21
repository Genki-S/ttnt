require 'minitest/autorun'
require_relative './fizzbuzz'

class TestFizzBuzz < Minitest::Test
  def test_fizzbuzz
    fb = FizzBuzz.new
    assert_equal "fizzbuzz", fb.convert(15)
    assert_equal "fizzbuzz", fb.convert(30)
    assert_equal "fizzbuzz", fb.convert(45)
  end
end
