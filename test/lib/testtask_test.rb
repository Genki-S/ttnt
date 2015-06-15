require 'test_helper'
require 'ttnt/testtask'
require 'rake/testtask'

class TestTaskTest < Minitest::Test
  def setup
    @name = 'sample_name'
    @rake_task = nil
    # This will be in users' Rakefiles
    Rake::TestTask.new { |t|
      t.name = @name
      t.libs << 'test'
      t.pattern = 'test/**/*_test.rb'
      TTNT::TestTask.new(t)
      @rake_task = t # save for testing purpose
    }
  end

  def test_find_by_name
    assert_equal TTNT::TestTask.find_by_name(@name), TTNT::TestTask.instances.first
  end

  def test_attributes
    ttnt_task = TTNT::TestTask.find_by_name(@name)
    assert_equal @rake_task.libs, ttnt_task.libs
    assert_equal @rake_task.pattern, ttnt_task.pattern
  end
end
