require 'test_helper'
require 'ttnt/testtask'
require 'rake/testtask'

class TestTaskTest < Minitest::Test
  def setup
    @name = 'sample_name'
    @rake_task = nil
    # This will be in users' Rakefiles
    @ttnt_task = Rake::TestTask.new { |t|
      t.name = @name
      t.libs << 'test'
      t.pattern = 'test/**/*_test.rb'
      TTNT::TestTask.new(t)
      @rake_task = t # save for testing purpose
    }
  end

  def test_define_rake_tasks
    assert Rake::Task.task_defined?("ttnt:#{@name}:anchor"),
      "`ttnt:#{@name}:anchor` task should be defined"
    assert Rake::Task.task_defined?("ttnt:#{@name}:run"),
      "`ttnt:#{@name}:run` task should be defined"
  end

  def test_attributes
    assert_equal @rake_task.libs, @ttnt_task.libs
    assert_equal @rake_task.pattern, @ttnt_task.pattern
  end
end
