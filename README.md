[![Rubytest](https://rubyworks.github.io/rubytest/assets/images/test_pattern.jpg)](https://rubyworks.github.io/rubytest)

# Rubytest

[![Gem Version](https://img.shields.io/gem/v/rubytest.svg?style=flat)](https://rubygems.org/gems/rubytest)
[![Build Status](https://github.com/rubyworks/rubytest/actions/workflows/test.yml/badge.svg)](https://github.com/rubyworks/rubytest/actions/workflows/test.yml)
[![Report Issue](https://img.shields.io/github/issues/rubyworks/rubytest.svg?style=flat)](https://github.com/rubyworks/rubytest/issues)


Rubytest is Ruby's Universal Test Harness. Think of it as a *testing meta-framework*.
It defines a straight-forward specification that any application can use to create
their own testing DSLs. Rubytest can be used for testing end-user applications directly
or as the backend of a test framework. Since Rubytest controls the backend, multiple test
frameworks can be used in a single test suite, all of which can be run through one uniform
interface in a single process!


## Specification

The universal access point for testing is the `$TEST_SUITE` global array. A test
framework need only add compliant test objects to `$TEST_SUITE`.
Rubytest will iterate through these objects. If a test object responds to
`#call`, it is run as a test procedure. If it responds to `#each` it is iterated
over as a test case with each entry handled in the same manner. All test
objects must respond to `#to_s` so their description can be used in test
reports.

Rubytest handles assertions with [BRASS](https://github.com/rubyworks/brass)
compliance. Any raised exception that responds to `#assertion?` in the
affirmative is taken to be a failed assertion rather than simply an error.
A test framework may raise a `NotImplementedError` to have a test recorded
as *todo* --a _pending_ exception to remind the developer of tests that still
need to be written. The `NotImplementedError` is a standard Ruby exception
and a subclass of `ScriptError`. The exception can also set a priority level
to indicate the urgency of the pending test. Priorities of -1 or lower
will generally not be brought to the attention of testers unless explicitly
configured to do so.

That is the crux of Rubytest specification. Rubytest supports some
additional features that can make its usage even more convenient.


## Installation

Rubytest is available as a Gem package.

    $ gem install rubytest


## Running Tests

There are a few ways to run tests.

### Via Command-line Tool

The easiest way to run tests is via the command line tool:

    $ rubytest -Ilib test/test_*.rb

The command line tool takes various options, most of which correspond directly
to the configuration options of the `Test.run/Test.configure` API. Use
`-h/--help` to see them all.

If you are using a build tool to run your tests, such as Rake, shelling
out to `rubytest` is a good way to go as it keeps your test environment as
pristine as possible, e.g.

    desc "run tests"
    task :test
      sh "rubytest"
    end

### Via Runner Scripts

You can write your own runner script using the Rubytest API:

    require 'rubytest'

    Test.run! do |r|
      r.loadpath 'lib'
      r.test_files 'test/test_*.rb'
    end

Put that in a `test/runner.rb` script and run it with `ruby` or
add `#!/usr/bin/env ruby` at the top and put it in `bin/test`
setting `chmod u+x bin/test`. Either way, you now have your test
runner.


## Requirements

Rubytest uses the [ANSI](https://github.com/rubyworks/ansi) gem for color output.


## Development

Rubytest is a [Rubyworks](https://rubyworks.github.io) project.


## Reference Material

* [Standard Definition Of Unit Test](http://c2.com/cgi/wiki?StandardDefinitionOfUnitTest)
* [BRASS Assertions Standard](https://github.com/rubyworks/brass)


## Copyrights

Copyright (c) 2011 Rubyworks

Made available according to the terms of the **BSD-2-Clause** license.

See LICENSE.txt for details.
