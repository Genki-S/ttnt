# TTNT: Test This, Not That!

[![Build Status](https://travis-ci.org/Genki-S/ttnt.svg?branch=master)](https://travis-ci.org/Genki-S/ttnt)
[![Coverage Status](https://coveralls.io/repos/Genki-S/ttnt/badge.svg?branch=master)](https://coveralls.io/r/Genki-S/ttnt?branch=master)
[![Code Climate](https://codeclimate.com/github/Genki-S/ttnt/badges/gpa.svg)](https://codeclimate.com/github/Genki-S/ttnt)
[![Dependency Status](https://gemnasium.com/Genki-S/ttnt.svg)](https://gemnasium.com/Genki-S/ttnt)

Stop running tests which are clearly not affected by the change you introduced in your commit!

Started as a [Google Summer of Code 2015](http://www.google-melange.com/gsoc/homepage/google/gsoc2015) project with mentoring organization [Ruby on Rails](http://rubyonrails.org/), with idea based on [Aaron Patterson](https://twitter.com/tenderlove)'s article ["Predicting Test Failures"](http://tenderlovemaking.com/2015/02/13/predicting-test-failues.html).

## Goal of this project

[rails/rails](https://github.com/rails/rails) has a problem that CI builds take hours to finish. This project aims to solve that problem by making it possible to run only tests related to changes introduced in target commits/branches/PRs.

## Terminology

- test-to-code mapping
    - mapping which maps test (file name) to code (file name and line number) executed on that test run for a given commit
    - this will be used to determine tests that are affected by changes in code
- base commit
    - the commit to which the tests you should run will be calculated (e.g. the latest commit of master branch)
    - this commit should have test-to-code mapping
- target commit
    - the commit on which you want to select tests you should run (e.g. HEAD of your feature branch)
    - this commit does not have to have test-to-code mapping

## Current Status

This project is still in an early stage and we are experimenting the best approach to solve the problem.

Currently, this program does:

- Generate test-to-code mapping with `$ rake ttnt:test:anchor`
- Select tests related to the change between base commit and current HEAD, and run the selected tests

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ttnt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ttnt

### Define Rake tasks

TTNT allows you to define its tasks according to an existing `Rake::TestTask` object like:

```ruby
require 'rake/testtask'
require 'ttnt/testtask'

t = Rake::TestTask.new do |t|
  t.libs << 'test'
  t.name = 'task_name'
end

TTNT::TestTask.new(t)
```

This will define 2 tasks: `ttnt:task_name:anchor` and `ttnt:task_name:run`. Usage for those tasks are described later in this document.

You can also instantiate a new `TTNT::TestTask` object and specify certain options like:

```ruby
require 'ttnt/testtask'

TTNT::TestTask.new do |t|
  t.code_files = FileList['lib/**/*.rb'] - FileList['lib/vendor/**/*.rb']
  t.test_files = 'test/**/*_test.rb'
end
```

You can specify the same options as `Rake::TestTask`.
Additionally, there is an option which is specific to TTNT:

- `code_files`
  - Specifies code files TTNT uses to select tests. Changes in files not listed here do not affect the test selection. Defaults to all files under the directory `Rakefile` resides.

## Requirements

Developed and only tested under ruby version 2.2.2.

## Usage

### Produce test-to-code mapping for a given commit

If you defined TTNT rake task as described above, you can run following command to produce test-to-code mapping:

```sh
$ rake ttnt:my_test_name:anchor
```

### Select tests

If you defined TTNT rake task as described above, you can run following command to run selected tests.

```sh
$ rake ttnt:my_test_name:run
```

#### Options

You can run test files one by one by setting `ISOLATED` environment variable:

```
$ rake ttnt:my_test_name:run ISOLATED=1
```

With isolated option, you can set `FAIL_FAST` environment variable to stop running successive tests after a test has failed:

```
$ rake ttnt:my_test_name:run ISOLATED=1 FAIL_FAST=1
```

## Current Limitations

- Test selection algorithm is not perfect yet (it may produce false-positives and false-negatives)
- Only supports git
- Only supports MiniTest
- Only select test files, not fine-grained test cases
- And a lot more!

This gem can only produce test-to-code mapping "from a single test file to code lines executed"
(not fine-grained mapping "from a single test **case** to code lines executed").
This is due to the way Ruby's coverage library works. Details are covered in [my proposal](https://github.com/Genki-S/gsoc2015/blob/master/proposal.md#2-run-each-test-case-from-scratch-requiring-all-files-for-every-run).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Genki-S/ttnt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://www.contributor-covenant.org) code of conduct.

I really :heart: getting interesting ideas, so please don't hesitate to [open a issue](https://github.com/Genki-S/ttnt/issues/new) to share your ideas for me! Any comment will be valuable especially in this early development stage. I am collecting interesting ideas which I cannot start working on soon [here at Trello](https://trello.com/b/z232DXnq/ttnt).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

