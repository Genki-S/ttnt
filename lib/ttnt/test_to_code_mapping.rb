require 'rugged'
require 'json'
require 'set'

# Terminologies:
#   spectra: { filename => [line, numbers, executed], ... }
#   mapping: { test_file => spectra }

module TTNT
  class TestToCodeMapping
    def initialize(repo)
      @repo = repo
      raise 'Not in a git repository' unless @repo
    end

    def append_from_coverage(test, coverage)
      spectra = normalize_path(select_project_files(spectra_from_coverage(coverage)))
      save_mapping(test: test, spectra: spectra)
    end

    def read_mapping
      if File.exists?(mapping_file)
        JSON.parse(File.read(mapping_file))
      else
        {}
      end
    end

    # Get tests affected from change of file `file` at line number `lineno`
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

    # FIXME: this might not be the responsibility for this class
    def save_commit_info(sha)
      unless File.directory?(File.dirname(commit_info_file))
        FileUtils.mkdir_p(File.dirname(commit_info_file))
      end
      File.write(commit_info_file, sha)
    end

    private

    def normalized_path(file)
      File.expand_path(file).sub(@repo.workdir, '')
    end

    def normalize_path(spectra)
      spectra.map do |filename, lines|
        [normalized_path(filename), lines]
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

    def save_mapping(test:, spectra:)
      dir = base_savedir
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end
      mapping = read_mapping.merge({ test => spectra })
      File.write(mapping_file, mapping.to_json)
    end

    def base_savedir
      "#{@repo.workdir}/.ttnt"
    end

    def mapping_file
      "#{base_savedir}/test_to_code_mapping.json"
    end

    def commit_info_file
      "#{base_savedir}/commit_obj.txt"
    end
  end
end
