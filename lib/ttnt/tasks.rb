require 'rake/testtask'
require 'ttnt/testtask'

# https://github.com/bundler/bundler/blob/master/lib/bundler/gem_helper.rb
module TTNT
  class TaskHelper
    include Rake::DSL if defined? Rake::DSL

    def self.install_tasks
      new.install
    end

    def install
      namespace :ttnt do
        desc 'Generate test-to-code mapping for current commit object'
        task 'anchor' do
          puts "Hello Rake!"
        end
      end
    end
  end
end

TTNT::TaskHelper.install_tasks
