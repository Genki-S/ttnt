require 'test_helper'
require 'ttnt/testtask'
require 'rake/testtask'

class TestTaskTest < Minitest::Test
  def setup
    @name = 'sample_name'
    @rake_task, @ttnt_task = nil, nil
    # This will be in users' Rakefiles
    @rake_task = Rake::TestTask.new { |t|
      t.name = @name
      t.libs << 'test'
      t.pattern = 'test/**/*_test.rb'
      @ttnt_task = TTNT::TestTask.new(t)
    }
  end

  def test_define_rake_tasks
    assert Rake::Task.task_defined?("ttnt:#{@name}:anchor"),
      "`ttnt:#{@name}:anchor` task should be defined"
    assert Rake::Task.task_defined?("ttnt:#{@name}:run"),
      "`ttnt:#{@name}:run` task should be defined"
  end

  def test_composing_rake_testtask
    assert_equal @rake_task, @ttnt_task.rake_testtask
  end
end
