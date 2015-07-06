require 'set'
require 'rugged'
require 'ttnt/metadata'
require 'ttnt/test_to_code_mapping'

module TTNT
  # Select tests using git information and {TestToCodeMapping}
  class TestSelector

    attr_reader :tests

    # @param repo [Rugged::Reposiotry] repository of the project
    # @param target_sha [String] sha of the target object
    # @param test_files [#include?] candidate test files
    def initialize(repo, target_sha, test_files)
      @repo = repo
      @metadata = MetaData.new(repo, target_sha)
      @target_obj = @repo.lookup(target_sha)

      # Base should be the commit `ttnt:anchor` has run on.
      # NOT the one test-to-code mapping was commited to.
      @base_obj = find_anchored_commit

      @test_files = test_files
    end

    # Select tests using differences in base_sha...target_sha and the latest
    # TestToCodeMapping committed to base_sha.
    #
    # @return [Set] a set of tests that might be affected by changes in base_sha...target_sha
    def select_tests!
      # TODO: if test-to-code-mapping is not found (ttnt-anchor has not been run)
      @tests ||= Set.new
      diff = @base_obj.diff(@target_obj)
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
      @mapping ||= TTNT::TestToCodeMapping.new(@repo, @target_obj.oid)
    end

    # Select tests which are affected by the change of given patch.
    #
    # @param patch [Rugged::Patch]
    # @return [Set] set of selected tests
    def select_tests_from_patch(patch)
      file = patch.delta.old_file[:path]
      patch.each_hunk do |hunk|
        # TODO: think if this selection covers all possibilities
        hunk.each_line do |line|
          case line.line_origin
          when :addition
            # FIXME: new_lineno is suspicious
            #        (what if hunk1 adds 100 lines and hunk2 add 1 line?)
            @tests += mapping.get_tests(file: file, lineno: line.new_lineno)
          when :deletion
            @tests += mapping.get_tests(file: file, lineno: line.old_lineno)
          end
        end
      end
    end

    # Find the commit `rake ttnt:test:anchor` has been run on.
    def find_anchored_commit
      @repo.lookup(@metadata['anchored_commit'])
    end

    # Check if given file is a test file
    #
    # @param filename [String]
    def test_file?(filename)
      @test_files.include?(filename)
    end
  end
end
