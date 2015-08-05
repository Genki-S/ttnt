require 'rake'

module TTNT
  class << self
    def root_dir
      # FIXME: cache this
      # currently caching this causes some tests to randomly fail.
      Rake.application.find_rakefile_location[1]
    end
  end
end
