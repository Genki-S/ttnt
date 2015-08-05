require 'rake'

module TTNT
  class << self
    def root_dir
      @root_dir ||= Rake.application.find_rakefile_location[1]
    end
  end
end
