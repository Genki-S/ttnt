require 'test_helper'
require 'ttnt/task_helper'

class TasksTest < Minitest::Test
  def test_define_rake_tasks
    name = 'sample_name'
    TTNT::TaskHelper.define_tasks(name)
    assert Rake::Task.task_defined?("ttnt:#{name}:anchor"),
      "`ttnt:#{name}:anchor` task should be defined"
    assert Rake::Task.task_defined?("ttnt:#{name}:run"),
      "`ttnt:#{name}:run` task should be defined"
  end
end
