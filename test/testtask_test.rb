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
      t.test_files = FileList['test/dummy_test.rb']
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

  def test_expanded_file_list
    # It gathers tests from both `pattern` and `test_files` option for Rake::TestTask
    test_files = Rake::FileList['test/**/*_test.rb'] + ['test/dummy_test.rb']
    assert_equal test_files, @ttnt_task.expanded_file_list
  end

  def test_instance_without_passing_rake_task
    default_rake_task = Rake::TestTask.new
    ttnt_task = TTNT::TestTask.new
    assert_equal default_rake_task.name, ttnt_task.instance_variable_get(:@rake_testtask).name
  end

  def test_yield_and_configure
    test_files = ['foo_test.rb', 'bar_test.rb']
    code_files = ['foo.rb', 'bar.rb']
    ttnt_task = TTNT::TestTask.new { |t|
      t.test_files = test_files
      t.code_files = code_files
    }
    assert_equal test_files, ttnt_task.test_files
    assert_equal code_files, ttnt_task.code_files
  end
end
