require 'ttnt/storage'

module TTNT
  class MetaData
    STORAGE_SECTION = 'meta'

    def initialize(repo)
      @storage = Storage.new(repo)
      read!
    end

    def get(name)
      @data[name]
    end

    def set(name, value)
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
