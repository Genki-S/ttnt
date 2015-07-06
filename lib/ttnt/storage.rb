module TTNT
  # A storage to store TTNT data such as test-to-code mapping and metadata.
  class Storage
    def initialize(repo)
      @repo = repo
    end

    # Read data in section from the storage.
    #
    # @param section [String]
    # @return [Hash]
    def read(section)
      if File.size?(filename)
        JSON.parse(File.read(filename))[section] || {}
      else
        {}
      end
    end

    # Write value to section in the storage.
    # Locks the file so that concurrent write does not occur.
    #
    # @param section [String]
    # @param value [Hash]
    def write!(section, value)
      File.open(filename, File::RDWR|File::CREAT, 0644) do |f|
        f.flock(File::LOCK_EX)
        str = f.read
        data = if str.length > 0 then JSON.parse(str) else {} end
        data[section] = value
        f.rewind
        f.write(data.to_json)
        f.flush
        f.truncate(f.pos)
      end
    end

    private

    def filename
      "#{@repo.workdir}/.ttnt"
    end
  end
end
