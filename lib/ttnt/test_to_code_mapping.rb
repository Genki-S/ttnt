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
      new_mapping = {
        test_file => normalize_path(select_project_files(spectra_from_coverage(coverage)))
      }
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

    def get_tests(file:, lineno:)
      tests = Set.new
      mapping = read_mapping
      mapping.each do |test, spectra|
        lines = spectra[file]
        next unless lines
        n = lines.bsearch { |x| x >= lineno }
        if n == lineno
          tests << test
        end
      end
      tests
    end

    private

    def normalize_path(spectra)
      spectra.map do |filename, lines|
        [filename.sub(@repo.workdir, ''), lines]
      end.to_h
    end

    def select_project_files(spectra)
      spectra.select do |filename, lines|
        filename.start_with?(@repo.workdir)
      end
    end

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
