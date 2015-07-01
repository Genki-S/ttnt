require 'rake'

module TTNT
  module RakeHelper
    module_function

    def load_rakefile(rakefile)
      Rake.application = Rake::Application.new
      Rake.application.init
      Rake.application.instance_variable_set(:@rakefiles, [rakefile])
      Rake.application.load_rakefile
    end

    def rake(task)
      Dir.chdir(@repo.workdir) do
        result = capture { Rake::Task[task].execute }
        block_given? ? yield(result) : result
      end
    end
  end
end
