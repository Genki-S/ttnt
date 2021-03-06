require 'coverage'
require 'ttnt/test_to_code_mapping'
require 'ttnt/metadata'
require 'rugged'

test_file = $0

Coverage.start

at_exit do
  # Use current HEAD
  repo = Rugged::Repository.discover('.')
  sha = repo.head.target_id
  mapping = TTNT::TestToCodeMapping.new(repo)
  mapping.append_from_coverage(test_file, Coverage.result)
  mapping.write!

  metadata = TTNT::MetaData.new(repo)
  metadata['anchored_commit'] = sha
  metadata.write!
end
