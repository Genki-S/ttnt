require 'set'
require 'rugged'
require 'ttnt/metadata'
require 'ttnt/test_to_code_mapping'

module TTNT
  # Select tests using git information and {TestToCodeMapping}.
  class TestSelector

    attr_reader :tests

    # @param repo [Rugged::Reposiotry] repository of the project
    # @param target_sha [String] sha of the target object
    #   (nil means to target current working tree)
    # @param test_files [#include?] candidate test files
    def initialize(repo, target_sha, test_files)
      @repo = repo
      storage_src_sha = target_sha ? target_sha : @repo.head.target_id
      @metadata = MetaData.new(repo, storage_src_sha)
      @target_obj = @repo.lookup(target_sha) if target_sha

      # Base should be the commit `ttnt:anchor` has run on.
      # NOT the one test-to-code mapping was commited to.
      @base_obj = find_anchored_commit

      @test_files = test_files
    end

    # Select tests using differences in anchored commit and target commit
    # (or current working tree) and {TestToCodeMapping}.
    #
    # @return [Set] a set of tests that might be affected by changes in base_sha...target_sha
    def select_tests!
      # select all tests if anchored commit does not exist
      return Set.new(@test_files) unless @base_obj

      @tests ||= Set.new
      opts = {
        include_untracked: true,
        recurse_untracked_dirs: true
      }
      diff = @target_obj ? @base_obj.diff(@target_obj, opts) : @base_obj.diff_workdir(opts)
      diff.each_patch do |patch|
        file = patch.delta.old_file[:path]
        if test_file?(file)
          @tests << file
        else
          select_tests_from_patch(patch)
        end
      end
      @tests.delete(nil)
    end

    private

    def mapping
      sha = @target_obj ? @target_obj.oid : @repo.head.target_id
      @mapping ||= TTNT::TestToCodeMapping.new(@repo, sha)
    end

    # Select tests which are affected by the change of given patch.
    #
    # @param patch [Rugged::Patch]
    # @return [Set] set of selected tests
    def select_tests_from_patch(patch)
      target_lines = Set.new
      file = patch.delta.old_file[:path]
      prev_line = nil
      patch.each_hunk do |hunk|
        hunk.each_line do |line|
          case line.line_origin
          when :addition
            if prev_line && !prev_line.addition?
              target_lines << prev_line.old_lineno
            elsif prev_line.nil?
              target_lines << hunk.old_start
            end
          when :deletion
            target_lines << line.old_lineno
          end

          prev_line = line
        end
      end

      target_lines.each do |line|
        @tests += mapping.get_tests(file: file, lineno: line)
      end
    end

    # Find the commit `rake ttnt:test:anchor` has been run on.
    def find_anchored_commit
      if @metadata['anchored_commit']
        @repo.lookup(@metadata['anchored_commit'])
      else
        nil
      end
    end

    # Check if given file is a test file.
    #
    # @param filename [String]
    def test_file?(filename)
      @test_files.include?(filename)
    end
  end
end
