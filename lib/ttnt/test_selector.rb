require 'set'
require 'rugged'
require_relative './test_to_code_mapping'

module TTNT
  # Select tests using git information and {TestToCodeMapping}
  class TestSelector
    # @param repo [Rugged::Reposiotry] repository of the project
    # @param target_sha [String] sha of the target object
    # @param base_sha [String] sha of the base object
    def initialize(repo, target_sha, base_sha)
      @repo = repo
      @target_obj = @repo.lookup(target_sha)

      # Base should be the commit `ttnt:anchor` has run on.
      # NOT the one test-to-code mapping was commited to.
      @base_obj = find_anchored_commit(base_sha)
    end

    # Select tests using differences in base_sha...target_sha and the latest
    # TestToCodeMapping committed to base_sha
    #
    # @return [Set] a set of tests that might be affected by changes in base_sha...target_sha
    def select_tests
      tests = Set.new
      mapping = TTNT::TestToCodeMapping.new(@repo)
      # TODO: if mapping is not found (ttnt-anchor has not been run)

      diff = @base_obj.diff(@target_obj)
      diff.each_patch do |patch|
        file = patch.delta.old_file[:path]
        patch.each_hunk do |hunk|
          # TODO: think if this selection covers all possibilities
          hunk.each_line do |line|
            case line.line_origin
            when :addition
              # FIXME: new_lineno is suspicious
              #        (what if hunk1 adds 100 lines and hunk2 add 1 line?)
              tests += mapping.get_tests(file: file, lineno: line.new_lineno)
            when :deletion
              tests += mapping.get_tests(file: file, lineno: line.old_lineno)
            else
              # do nothing
            end
          end
        end
      end
      tests.delete(nil)
    end

    private

    # Find the commit `rake ttnt:test:anchor` has been run on.
    #
    # @param sha [String] sha of a commit from which search starts
    def find_anchored_commit(sha)
      ttnt_tree = @repo.lookup(@repo.lookup(sha).tree['.ttnt'][:oid])
      anchored_sha = @repo.lookup(ttnt_tree['commit_obj.txt'][:oid]).content
      @repo.lookup(anchored_sha)
    end
  end
end
