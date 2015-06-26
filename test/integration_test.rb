require 'test_helper'
require 'ttnt/test_to_code_mapping'

class IntegrationTest < TTNT::TestCase
  FIZZBUZZ_FIXTURE_DIR = File.expand_path('../fixtures/repositories/fizzbuzz', __FILE__).freeze

  def setup
    bundle_install
  end

  def test_mapping_generation
    generate_test_to_code_mapping
    Dir.chdir(@repodir) do
      commit_info = File.read('.ttnt/commit_obj.txt')
      assert_equal commit_info, @repo.head.target_id
      mapping = JSON.parse(File.read('.ttnt/test_to_code_mapping.json'))
      expected_mapping = {"test/buzz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 6, 7]},
                          "test/fizz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 5]},
                          "test/fizzbuzz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 3]},
                          "test/non_fizzbuzz_test.rb"=>{"lib/fizzbuzz.rb"=>[1, 2, 4, 6, 9]}}
      assert_equal expected_mapping, mapping
    end
  end

  def test_test_selection
    generate_test_to_code_mapping
    commit_ttnt_files
    Dir.chdir(@repodir) do
      system('git checkout -b make_fizz_wrong > /dev/null 2> /dev/null')
      # Make fizz wrong
      File.write('lib/fizzbuzz.rb',
                 File.read('lib/fizzbuzz.rb').sub('"fizz"', '"wrong"'))
      system('git commit -am "Make fizz wrong" > /dev/null 2> /dev/null')
      rake_run_output = `bundle exec rake test 2> /dev/null`
      ttnt_run_output = `bundle exec rake ttnt:test:run 2> /dev/null`
      assert_match(/4 runs, 10 assertions, 1 failures/, rake_run_output)
      # Now `rake ttnt:test:run` just lists selected tests and does not run tests
      # assert_match(/1 runs, 1 assertions, 1 failures/, ttnt_run_output)
      assert_equal ttnt_run_output.split("\n").count, 1,
        "Only test/fizz_test.rb should be selected." \
        " Selected tests: #{ttnt_run_output.split("\n").join(', ')}"
    end
  end

  private

  def bundle_install
    ttnt_root = File.expand_path('../..', __FILE__)
    Dir.chdir(@repodir) do
      File.open('Gemfile', 'a') do |f|
        f.puts "gem 'ttnt', path: '#{ttnt_root}'"
      end
      system('bundle install > /dev/null')
    end
  end

  def generate_test_to_code_mapping
    Dir.chdir(@repodir) do
      system('bundle exec rake ttnt:test:anchor > /dev/null 2> /dev/null')
    end
  end

  def commit_ttnt_files
    Dir.chdir(@repodir) do
      # FIXME: Use rugged
      system('git add .ttnt > /dev/null 2> /dev/null')
      system('git commit -m "Add ttnt files" > /dev/null 2> /dev/null')
    end
  end
end
