require 'rake'

module TTNT
  module RakeHelper
    def self.load_rakefile(rakefile)
      Rake.application = Rake::Application.new
      Rake.application.init
      Rake.application.instance_variable_set(:@rakefiles, [rakefile])
      Rake.application.load_rakefile
    end

    def self.rake(task)
      result = capture { Rake::Task[task].execute }
      block_given? ? yield(result) : result
    end

    def self.capture
      captured_stream = Tempfile.new("stdout")
      origin_stream   = $stdout.dup
      $stdout.reopen(captured_stream)

      yield

      $stdout.rewind
      return captured_stream.read
    ensure
      captured_stream.close
      captured_stream.unlink
      $stdout.reopen(origin_stream)
    end
  end
end
