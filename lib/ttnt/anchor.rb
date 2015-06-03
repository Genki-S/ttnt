require 'coverage'
require 'ttnt/storage'
require 'rugged'

Coverage.start

at_exit do
  # Use current HEAD
  sha = Rugged::Repository.discover('.').head.target_id
  storage = TTNT::Storage.new(sha)
  storage.append(Coverage.result)
end
