require 'ttnt/ttnt_module'

module TTNT
  # A utility class to store TTNT data such as test-to-code mapping and metadata.
  class Storage
    # Initialize the storage from given repo and sha. This reads contents from
    # a file `.ttnt`. When sha is not nil, contents of the file on that commit
    # is read. Data can be written only when sha is nil (written to current
    # working tree).
    #
    # @param repo [Rugged::Repository]
    # @param sha [String] sha of the commit from which data should be read.
    #   nil means reading from/writing to current working tree.
    def initialize(repo, sha = nil)
      @repo = repo
      @sha = sha
    end

    # Read data in section from the storage.
    #
    # @param section [String]
    # @return [Hash]
    def read(section)
      str = read_storage_content
      if str.length > 0
        JSON.parse(str)[section] || {}
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
      raise 'Data cannot be written to the storage back in git history' unless @sha.nil?
      File.open(filename, File::RDWR|File::CREAT, 0644) do |f|
        f.flock(File::LOCK_EX)
        str = f.read
        data = str.length > 0 ? JSON.parse(str) : {}
        data[section] = value
        f.rewind
        f.write(data.to_json)
        f.flush
        f.truncate(f.pos)
      end
    end

    private

    def filename
      "#{TTNT.root_dir}/.ttnt"
    end

    def filename_from_repository_root
      filename.gsub(@repo.workdir, '')
    end

    def storage_file_oid
      tree = @repo.lookup(@sha).tree
      paths = filename_from_repository_root.split(File::SEPARATOR)
      dirs, filename = paths[0...-1], paths[-1]
      dirs.each do |dir|
        obj = tree[dir]
        return nil unless obj
        tree = @repo.lookup(obj[:oid])
      end
      obj = tree[filename]
      return nil unless obj
      obj[:oid]
    end

    def read_storage_content
      if @sha
        oid = storage_file_oid
        if oid
          @repo.lookup(oid).content
        else
          '' # Storage file is not committed for the commit of given sha
        end
      else
        File.exist?(filename) ? File.read(filename) : ''
      end
    end
  end
end
