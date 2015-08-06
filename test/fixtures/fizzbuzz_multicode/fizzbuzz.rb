require_relative './fizz_detectable'
require_relative './buzz_detectable'
require_relative './fizzbuzz_detectable'

class FizzBuzz
  include FizzDetectable
  include BuzzDetectable
  include FizzBuzzDetectable

  def convert(n)
    if fizzbuzz?(n)
      "fizzbuzz"
    elsif buzz?(n)
      "buzz"
    elsif fizz?(n)
      "fizz"
    else
      n
    end
  end
end
