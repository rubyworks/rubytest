# Ruby Test

[Homepage](http://rubyworks.github.com/test) |
[User Guide](http://wiki.github.com/rubyworks/test) |
[Development](http://github.com/rubyworks/test) |
[Issues](http://github.com/rubyworks/test/issues)

## Description

Ruby Test is a universal test harness for use by any Ruby test framework.
It defines a simple specification for compliance, which allows Ruby Test
to run the framework's tests, and even test across multiple frameworks
in a single pass.

## Specification

Ruby Test defines a straight-forward specification that any test framework can 
easily support which allows Ruby Test to run the frameworks tests through a
single uniform user interface.

The universal access point for testing is the `$TEST_SUITE` global array. A test
framework need only add compliant test objects to `$TEST_SUITE`. 
Ruby Test will iterate through these objects. If a test object responds to
`#call`, it is run as a test procedure. If it responds to `#each` it is iterated
over as a test case with each entry handled in the same manner. All test 
objects must respond to `#to_s` so their description can be used in test
reports.

Any raised exception that responds to `#assertion?` in the affirmative is taken
to be a failed assertion rather than simply an error. Ruby Test extends the
Exception class to support this method for all exceptions.

A test framework may raise a `NotImplementedError` to have a test recorded
as "pending" --a _todo_ item to remind the developer of tests that still
need to be written. The `NotImplementedError` is a standard Ruby exception
and a subclass of `ScriptError`.

If the `NotImplmentedError` responds in the affirmative to `#assertion?` then
the test is taken to be a purposeful _omission_, rather than simply pending.

That is the crux of Ruby Test specification. Ruby Test supports some
additional features that can makes its usage even more convenient.
See the [Wiki](http://github.com/rubyworks/test/wiki) for further details.


## Usage

There are a few ways to run tests. First, there is a command line tool:

    $ ruby-test

The command line tool takes various options, use `--help` to see them.
Be sure to load in your test framework or framework's Ruby Test adapter.

Preconfigurations can be defined in a `.test` file, e.g.

    Test.run 'default' do |r|
      r.format = 'progress'
      r.requires << 'lemon'
      r.files << 'test/*_case.rb'
    end

There is a 'test/autorun.rb' library script can be loaded which creates an
`at_exit` procedure.

    $ ruby -rtest/autorun

And there is a Rake task.

    require 'test/rake'

A Detroit plugin is in the works and should be available soon.


## Installation

Ruby Test is available as Gem package.

    $ gem install test


## Requirements

Ruby test uses the [ANSI](http://rubyworks.github.com/ansi) gem for color output.

Because of the "foundational" nature of this library we will look at removing
this dependencies for future versions, but for early development the 
requirements does the job and does it well.


## Development

Ruby Test is still a "nuby" gem. Please feel OBLIGATED to help improve it ;-)

Ruby Test is a [RubyWorks](http://rubyworks.github.com) project. If you can't
contribue code, you can still help out by contributing to our development fund.


## Reference Material

[1] [Standard Definition Of Unit Test](http://c2.com/cgi/wiki?StandardDefinitionOfUnitTest)


## Copyrights

Copyright (c) 2011 Thomas Sawyer, Rubyworks

Made available according to the terms of the <b>FreeBSD license</b>.

See COPYING.rdoc for details.
