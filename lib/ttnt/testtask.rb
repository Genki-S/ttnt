module TTNT
  class TestTask
    @@instances = []

    def self.instances
      @@instances
    end

    ATTRIBUTES = %i(
      name
      libs
      pattern
      options
      test_files
      warning
      loader
      ruby_opts
      description
      pattern
    ).freeze

    ATTRIBUTES.each do |attr|
      attr_reader attr
    end

    def initialize(rake_test_task)
      ATTRIBUTES.each do |attr|
        if rake_test_task.respond_to?(attr)
          instance_eval("@#{attr.to_s} = rake_test_task.#{attr.to_s}")
        end
      end
      @@instances << self
    end
  end
end
