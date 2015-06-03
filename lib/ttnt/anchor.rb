require 'coverage'

Coverage.start

at_exit do
  p Coverage.result
end
