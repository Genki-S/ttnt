require 'coverage'
require 'ttnt/storage'
require 'rugged'

test_file = $0

Coverage.start

at_exit do
  # Use current HEAD
  sha = Rugged::Repository.discover('.').head.target_id
  storage = TTNT::Storage.new(sha)
  storage.append(test_file, Coverage.result)
end
