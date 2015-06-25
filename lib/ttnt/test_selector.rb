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
      @base_obj = find_anchoring_commit
    end

    # Select tests using differences in base_sha...target_sha and the latest
    # TestToCodeMapping committed to base_sha.
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

    # Walk through the history starting from HEAD and find the nearest
    # anchoring commit. Basically the same as doing
    # `git log -- .ttnt/test_to_code_mapping.json` and take the first commit.
    #
    # @return [Rugged::Commit] the latest commit mapping file is committed
    def find_anchoring_commit
      head_oid = lookup_mapping_file(@repo.head.target.tree)[:oid]
      walker = Rugged::Walker.new(@repo)
      walker.push(@repo.head.target.oid)
      prev_commit = nil
      found = nil
      walker.each do |commit|
        obj = lookup_mapping_file(commit.tree)
        if obj.nil? || obj[:oid] != head_oid
          found = prev_commit
          break
        end
        prev_commit = commit
      end
      found
    end

    def lookup_mapping_file(tree)
      begin
        @repo.lookup(tree['.ttnt'][:oid])['test_to_code_mapping.json']
      rescue
        nil
      end
    end
  end
end
