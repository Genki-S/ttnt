# TTNT: Test This, Not That!

Developing under [Google Summer of Code 2015](http://www.google-melange.com/gsoc/homepage/google/gsoc2015) with mentoring organization [Ruby on Rails](http://rubyonrails.org/).

Full proposal of this project is [here](https://github.com/Genki-S/gsoc2015/blob/master/proposal.md) (might be obsolete in some ways, read this README about this project itself rather than the proposal).

## Goal of this project

[rails/rails](https://github.com/rails/rails) has a problem that CI builds take hours to finish. This project aims to solve that problem by making it possible to run only tests related to changes introduced in target commits/branches/PRs.

### Approach

The idea is based on [Aaron Patterson](https://twitter.com/tenderlove)'s article ["Predicting Test Failures"](http://tenderlovemaking.com/2015/02/13/predicting-test-failues.html). This program uses differences in code between base commit (say, the latest commit of master branch) and target commit (say, HEAD of your feature branch) to calculate which test cases are affected by that change.

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

- Generate test-to-code mapping for a given commit
- Given base commit and target commit, output test files you should run

Limitations:

- Test selection algorithm is not perfect yet (it may produce false-positives and false-negatives)
- Only supports git
- Only supports MiniTest
- Only select test files, not fine-grained test cases
- And a lot more!

## Testing it out

I integrated it under [use_ttnt branch of my forked version of rails/rails](https://github.com/Genki-S/rails/tree/use_ttnt). You can get the idea by [looking at it's diff](https://github.com/rails/rails/compare/master...Genki-S:use_ttnt) (basically I've just added `ttnt:anchor` rake task, which uses `ttnt-anchor` program in place of ruby when running isolated test). To test this out:

```
$ git clone https://github.com/Genki-S/rails
$ git checkout use_ttnt
$ # Or add my repository as a remote of your rails/rails and checkout my branch
$ bundle install
$ cd actionmailer
$ # I recommend running it under one gem because it's long to run for all gems
$ bundle exec rake ttnt:anchor
```

This produces code-to-test-mapping as `.ttnt/code-to-test-mapping/BASE_COMMIT_SHA/TEST_FILE_NAME.json` to your project root.

To try selecting tests using ttnt, introduce some commits which will break some tests on which you ran `rake ttnt:anchor` with the previous commands, and execute the following:

```
$ ttnt BASE_COMMIT_SHA
```

Or try out my [ttnt_selection_test branch](https://github.com/Genki-S/rails/tree/ttnt_selection_test) on which I have done it for you (though it's not a great example). More information is written on the README on that branch.

## Roadmap

Roadmap is under construction.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ttnt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ttnt

### Define rake tasks

You can define TTNT rake tasks by following steps:

1. `require 'ttnt/tasks'`
2. Define `TTNT::TestTask` when defining `Rake::TestTask`

Your `Rakefile` will look like this:

```
require 'rake/testtask'
require 'ttnt/tasks'

Rake::TestTask.new { |t|
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
  TTNT::TestTask.new(t)
}
```

## Requirements

Developed and only tested under ruby version 2.2.1.

## Usage

### Produce test-to-code mapping for a given commit

### Using rake task

If you defined TTNT rake task as described above, you can run following command to produce test-to-code mapping:

```
$ rake ttnt:anchor
```

### Using ttnt-anchor executable

This pre-computation is required to select tests later.

Basically, you can substitute `ruby` command with `ttnt-anchor` command.
For example, if you want to produce test-to-code mapping for `test/mail_layout_test.rb` in `ActionMailer` of rails/rails:

```
$ cd /your/local/rails/rails
$ git checkout BASE_COMMIT
$ cd actionmailer
$ ttnt-anchor -w -Itest test/mail_layout_test.rb -n test_explicit_class_layout
```

(this example is taken from ["Contributing to Ruby on Rails — Ruby on Rails Guides"](http://edgeguides.rubyonrails.org/contributing_to_ruby_on_rails.html#running-tests)).

This will produce test-to-code mapping for the test file `test/mail_layout_test.rb` under `.ttnt/BASE_COMMIT_SHA/test_to_code_mapping/TEST_FILE_NAME.json` which resides in your project base directory (the same repository in which `.git` directory resides).

### Select tests

```
$ git checkout TARGET_COMMIT
$ ttnt BASE_COMMIT
```

This will assume test-to-code mapping is properly produced for the BASE\_COMMIT.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Genki-S/ttnt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

Please don't hesitate to [open a issue](https://github.com/Genki-S/ttnt/issues/new) to share your ideas for me! Any comment will be valuable especially in this early development stage.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

