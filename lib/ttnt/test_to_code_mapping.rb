require 'ttnt/storage'
require 'rugged'
require 'json'
require 'set'

module TTNT
  # Mapping from test file to executed code (i.e. coverage without execution count).
  #
  # Terminologies:
  #   spectra: { filename => [line, numbers, executed], ... }
  #   mapping: { test_file => spectra }
  class TestToCodeMapping
    STORAGE_SECTION = 'mapping'

    # @param repo [Rugged::Reposiotry] repository to save test-to-code mapping
    #   (only repo.workdir is used to determine where to save the mapping file)
    # @param sha [String] sha of commit from which mapping is read.
    #   nil means to read from current working tree. see {Storage} for more.
    def initialize(repo, sha = nil)
      @repo = repo
      @storage = Storage.new(repo, sha)
      raise 'Not in a git repository' unless @repo
    end

    # Append the new mapping to test-to-code mapping file.
    #
    # @param test [String] test file for which the coverage data is produced
    # @param coverage [Hash] coverage data generated using `Coverage.start` and `Coverage.result`
    # @return [void]
    def append_from_coverage(test, coverage)
      spectra = normalize_paths(select_project_files(spectra_from_coverage(coverage)))
      update_mapping_entry(test: test, spectra: spectra)
    end

    # Read test-to-code mapping from storage.
    #
    # @return [Hash] test-to-code mapping
    def read_mapping
      @storage.read(STORAGE_SECTION)
    end

    # Get tests affected from change of file `file` at line number `lineno`
    #
    # @param file [String] file name which might have effects on some tests
    # @param lineno [Integer] line number in the file which might have effects on some tests
    # @return [Set] a set of test files which might be affected by the change in file at lineno
    def get_tests(file:, lineno:)
      tests = Set.new
      read_mapping.each do |test, spectra|
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

    # Convert absolute path to relative path from the project (git repository) root.
    #
    # @param file [String] file name (absolute path)
    # @return [String] normalized file path
    def normalized_path(file)
      File.expand_path(file).sub(@repo.workdir, '')
    end

    # Normalize all file names in a spectra.
    #
    # @param spectra [Hash] spectra data
    # @return [Hash] spectra whose keys (file names) are normalized
    def normalize_paths(spectra)
      spectra.map do |filename, lines|
        [normalized_path(filename), lines]
      end.to_h
    end

    # Filter out the files outside of the target project using file path.
    #
    # @param spectra [Hash] spectra data
    # @return [Hash] spectra with only files inside the target project
    def select_project_files(spectra)
      spectra.select do |filename, lines|
        filename.start_with?(@repo.workdir)
      end
    end

    # Generate spectra data from Ruby coverage library's data
    #
    # @param cov [Hash] coverage data generated using `Coverage.result`
    # @return [Hash] spectra data
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

    # Update single test-to-code mapping entry.
    #
    # @param test [String] target test file
    # @param spectra [Hash] spectra data for when executing the test file
    # @return [void]
    def update_mapping_entry(test:, spectra:)
      mapping = read_mapping.merge({ test => spectra })
      @storage.write!(STORAGE_SECTION, mapping)
    end
  end
end
