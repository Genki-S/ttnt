require 'coverage'
require 'ttnt/test_to_code_mapping'
require 'rugged'

test_file = $0

Coverage.start

at_exit do
  # Use current HEAD
  sha = Rugged::Repository.discover('.').head.target_id
  mapping = TTNT::TestToCodeMapping.new(sha)
  mapping.append_from_coverage(test_file, Coverage.result)
end
