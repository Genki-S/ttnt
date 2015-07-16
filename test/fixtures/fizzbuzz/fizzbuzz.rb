def fizzbuzz_convert(n)
  if n % 15 == 0
    "fizzbuzz"
  elsif n % 3 == 0
    "fizz"
  elsif n % 5 == 0
    "buzz"
  else
    n
  end
end
