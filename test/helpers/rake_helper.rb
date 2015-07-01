require 'rake'

module TTNT
  module RakeHelper
    def self.load_rakefile(rakefile)
      Rake.application = Rake::Application.new
      Rake.application.init
      Rake.application.instance_variable_set(:@rakefiles, [rakefile])
      Rake.application.load_rakefile
    end

    def self.rake(task, dir: Dir.pwd)
      Dir.chdir(dir) do
        result = capture { Rake::Task[task].execute }
        block_given? ? yield(result) : result
      end
    end

    def self.capture
      captured_stream     = Tempfile.new("stdout")
      origin_stream       = $stdout.dup
      captured_stream_err = Tempfile.new("stderr")
      origin_stream_err   = $stderr.dup
      $stdout.reopen(captured_stream)
      $stderr.reopen(captured_stream_err)

      yield

      $stdout.rewind
      $stderr.rewind
      return { stdout: captured_stream.read, stderr: captured_stream_err.read }
    ensure
      captured_stream.close
      captured_stream.unlink
      captured_stream_err.close
      captured_stream_err.unlink
      $stdout.reopen(origin_stream)
      $stderr.reopen(origin_stream_err)
    end
  end
end
