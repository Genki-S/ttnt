require 'rugged'
require 'json'

module TTNT
  class Storage
    def initialize(sha)
      @sha = sha
      @repo = Rugged::Repository.discover('.')
      raise 'Not in a git repository' unless @repo
    end

    def append(new_coverage)
      cov = read_coverage.merge(new_coverage)
      save_coverage(cov)
    end

    def read_coverage
      if File.exists?(coverage_file)
        JSON.parse(File.read(coverage_file))
      else
        {}
      end
    end

    private

    def save_coverage(cov)
      unless File.directory?(File.dirname(coverage_file))
        FileUtils.mkdir_p(File.dirname(coverage_file))
      end
      File.write(coverage_file, cov.to_json)
    end

    def coverage_file
      "#{@repo.workdir}/.ttnt/#{@sha}/coverage.json"
    end
  end
end
