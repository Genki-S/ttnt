require 'rugged'
require 'json'

# Terminologies:
#   spectra: { filename => [line, numbers, executed], ... }

module TTNT
  class TestToCodeMapping
    DIRECTORY_SEPARATOR_PLACEHOLDER = '=+='.freeze

    def initialize(sha)
      @sha = sha
      @repo = Rugged::Repository.discover('.')
      raise 'Not in a git repository' unless @repo
    end

    def append_from_coverage(test, coverage)
      spectra =  normalize_path(select_project_files(spectra_from_coverage(coverage)))
      save_spectra(test: test, spectra: spectra)
    end

    def read_spectra(test:)
      if File.exists?(spectra_file(test: test))
        JSON.parse(File.read(spectra_file(test: test)))
      else
        {}
      end
    end

    def get_tests(file:, lineno:)
      tests = Set.new
      all_tests.each do |test|
        spectra = read_spectra(test: test)
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

    def save_spectra(test:, spectra:)
      dir = base_savedir
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end
      File.write(spectra_file(test: test), spectra.to_json)
    end

    def base_savedir
      "#{@repo.workdir}/.ttnt/#{@sha}/test_to_code_mapping"
    end

    def spectra_file(test:)
      filename = test.gsub('/', DIRECTORY_SEPARATOR_PLACEHOLDER)
      "#{base_savedir}/#{filename}.json"
    end

    def all_tests
      Dir["#{base_savedir}/*.json"].map do |filename|
        filename
          .sub(/.*\//, '')
          .sub(/\.json\Z/, '')
          .gsub(DIRECTORY_SEPARATOR_PLACEHOLDER, '/')
      end
    end
  end
end
