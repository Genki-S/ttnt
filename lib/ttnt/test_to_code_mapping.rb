require 'rugged'
require 'json'

# Terminologies:
#   spectra: { filename => [line, numbers, executed], ... }

module TTNT
  class TestToCodeMapping
    def initialize(sha)
      @sha = sha
      @repo = Rugged::Repository.discover('.')
      raise 'Not in a git repository' unless @repo
    end

    def append_from_coverage(test_file, coverage)
      new_mapping = { test_file => spectra_from_coverage(coverage) }
      mapping = read_mapping.merge(new_mapping)
      save(mapping)
    end

    def read_mapping
      if File.exists?(mapping_file)
        JSON.parse(File.read(mapping_file))
      else
        {}
      end
    end

    private

    def spectra_from_coverage(cov)
      spectra = Hash.new { |h, k| h[k] = [] }
      cov.each do |filename, executions|
        executions.each_with_index do |execution, i|
          next if execution.nil? || execution == 0
          spectra[filename] << i + 1
        end
      end
      spectra
    end

    def save(mapping)
      dir = File.dirname(mapping_file)
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end
      File.write(mapping_file, mapping.to_json)
    end

    def mapping_file
      "#{@repo.workdir}/.ttnt/#{@sha}/test_to_code_mapping.json"
    end
  end
end
