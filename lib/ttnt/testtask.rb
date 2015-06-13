module TTNT
  class TestTask
    @@instances = []

    def self.instances
      @@instances
    end

    ATTRIBUTES = %i(
      name
      libs
      verbose
      options
      warning
      pattern
      loader
      ruby_opts
      description
    ).freeze

    ATTRIBUTES.each do |attr|
      attr_reader attr
    end
    attr_reader :test_files

    def initialize(rake_test_task)
      ATTRIBUTES.each do |attr|
        if rake_test_task.respond_to?(attr)
          instance_eval("@#{attr.to_s} = rake_test_task.#{attr.to_s}")
        end
      end
      # Since test_files is not exposed in Rake::TestTask
      @test_files = rake_test_task.instance_variable_get('@test_files')
      @@instances << self
    end
  end
end
