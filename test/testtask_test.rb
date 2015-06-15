require 'test_helper'
require 'ttnt/testtask'
require 'rake/testtask'

class TestTaskTest < Minitest::Test
  def test_attributes
    rake_task = nil
    # This will be in users' Rakefiles
    Rake::TestTask.new { |t|
      t.libs << 'test'
      t.pattern = 'test/**/*_test.rb'
      TTNT::TestTask.new(t)
      rake_task = t # save for testing purpose
    }

    ttnt_task = TTNT::TestTask.instances.first
    assert_equal rake_task.libs, ttnt_task.libs
    assert_equal rake_task.pattern, ttnt_task.pattern
  end
end
