module TTNT
  module GitHelper
    module_function

    def git_commit(index, message)
      options = {}
      options[:tree]       = index.write_tree(@repo)
      options[:author]     = { email: "foo@bar.com", name: 'Author', time: Time.now }
      options[:committer]  = options[:author]
      options[:message]    = message
      options[:parents]    = @repo.empty? ? [] : [@repo.head.target].compact
      options[:update_ref] = 'HEAD'
      Rugged::Commit.create(@repo, options)
      index.write
    end

    def git_commit_am(message)
      index = @repo.index
      index.read_tree(@repo.head.target.tree) unless @repo.empty?
      index.add_all
      git_commit(index, message)
    end

    def git_rm_and_commit(file, message)
      index = @repo.index
      index.read_tree(@repo.head.target.tree) unless @repo.empty?
      index.remove(file.gsub(/^#{@repo.workdir}\//, ''))
      git_commit(index, message)
    end

    def git_checkout_b(branch)
      @repo.create_branch(branch)
      @repo.checkout(branch)
    end
  end
end
