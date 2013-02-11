# Ruby Test

[Homepage](http://rubyworks.github.com/rubytest) /
[User Guide](http://wiki.github.com/rubyworks/rubytest) /
[Development](http://github.com/rubyworks/rubytest) /
[Issues](http://github.com/rubyworks/rubytest/issues)

[![Build Status](https://secure.travis-ci.org/rubyworks/rubytest.png)](http://travis-ci.org/rubyworks/rubytest)
[![Gem Version](https://badge.fury.io/rb/rubytest.png)](http://badge.fury.io/rb/rubytest)


## Description

Ruby Test is a universal test harness for Ruby developers. It can be used
by any Ruby test framework. You can think of Ruby Test as a *meta test framework*. 
Ruby Test defines a straight-forward specification that any test framework
can utilize as it back-end. This makes it almost trivial to implement new
test frameworks. Ruby Test further allows tests from various frameworks
to all run through a single uniform user interface in a single pass.


## Specification

The universal access point for testing is the `$TEST_SUITE` global array. A test
framework need only add compliant test objects to `$TEST_SUITE`. 
Ruby Test will iterate through these objects. If a test object responds to
`#call`, it is run as a test procedure. If it responds to `#each` it is iterated
over as a test case with each entry handled in the same manner. All test 
objects must respond to `#to_s` so their description can be used in test
reports.

Ruby Test handles assertions with [BRASS](http://rubyworks.github.com/brass)
compliance. Any raised exception that responds to `#assertion?` in the
affirmative is taken to be a failed assertion rather than simply an error. 

A test framework may raise a `NotImplementedError` to have a test recorded
as *todo* --a _pending_ exception to remind the developer of tests that still
need to be written. The `NotImplementedError` is a standard Ruby exception
and a subclass of `ScriptError`. The exception can also set a priority level
to indicate the urgency of the pending test. Priorities of -1 or lower
will generally not be brought to the attention of testers unless explicitly 
configured to do so.

That is the crux of Ruby Test specification. Ruby Test supports some
additional features that can makes its usage even more convenient.
See the [Wiki](http://github.com/rubyworks/test/wiki) for further details.


## Installation

Ruby Test is available as a Gem package.

    $ gem install rubytest

Ruby Test is compliant with Setup.rb layout standard, so it can
also be installed in an FHS compliant fashion if necessary.


## Running Tests

There are a few ways to run tests. First, there is the command line tool
e.g.

    $ rubytest test/test_*.rb

The command line tool takes various options, use `-h/--help` to see them.

When running tests, you need to be sure to load in your test framework
or your framework's Ruby Test adapter. This is usually done via a helper
script in the test files, but might also be done via command line options,
e.g.

    $ rubytest -r lemon -r ae test/test_*.rb

Ruby Test supports [dotopts](http://rubyworks.github.com/dotopts) out of the
box, so it easy to setup reusable options. For example, a `.option` file
entry might be:

    rubytest
      -f progress
      -r spectroscope
      -r rspecial
      spec/spec_*.rb

There is also a Rake task. In your Rakefile,

    require 'rubytest/rake'

    Test::Rake::TestTask.new do |run|
      require 'lemon'
      run.files << 'test/test_*.rb'
    end

See the Wiki for more information on the different ways to run tests.


## Requirements

Ruby Test uses the [ANSI](http://rubyworks.github.com/ansi) gem for color output.

Because of the "foundational" nature of this library we will look at removing
this dependency for future versions, but for early development the 
requirements does the job and does it well.


## Development

Ruby Test is still a bit of a "nuby" gem. Please feel OBLIGATED to help improve it ;-)

Ruby Test is a [Rubyworks](http://rubyworks.github.com) project. If you can't
contribute code, you can still help out by contributing to our development fund.


## Reference Material

* [Standard Definition Of Unit Test](http://c2.com/cgi/wiki?StandardDefinitionOfUnitTest)
* [BRASS Assertions Standard](http:rubyworks.github.com/brass)


## Copyrights

Copyright (c) 2011 Rubyworks

Made available according to the terms of the <b>BSD-2-Clause</b> license.

See LICENSE.txt for details.

