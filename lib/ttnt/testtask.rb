require 'ttnt/task_helper'

module TTNT
  class TestTask
    @@instances = []

    def self.instances
      @@instances
    end

    def initialize(rake_test_task)
      TTNT::TaskHelper.define_tasks(rake_test_task.name)

      attributes = rake_test_task.instance_variables
      attributes.map! { |attribute| attribute[1..-1] }

      attributes.each do |ivar|
        self.class.class_eval("attr_accessor :#{ivar}")
        if rake_test_task.respond_to?(ivar)
          send(:"#{ivar}=", rake_test_task.send(:"#{ivar}"))
        end
      end
      # Since test_files is not exposed in Rake::TestTask
      @test_files = rake_test_task.instance_variable_get('@test_files')
      @@instances << self
    end
  end
end
