require 'ttnt/storage'

module TTNT
  class MetaData
    STORAGE_SECTION = 'meta'

    # @param repo [Rugged::Repository]
    # @param sha [String] sha of commit from which metadata is read from.
    #   nil means to read from current working tree. see {Storage} for more.
    def initialize(repo, sha)
      @storage = Storage.new(repo, sha)
      read!
    end

    def [](name)
      @data[name]
    end

    def []=(name, value)
      @data[name] = value
    end

    def read!
      @data = @storage.read(STORAGE_SECTION)
    end

    def write!
      @storage.write!(STORAGE_SECTION, @data)
    end
  end
end
