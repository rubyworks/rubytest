# Ruby Test

| Author    | Thomas Sawyer |
| License   | FreeBSD |
| Copyright | (c) 2011 Thomas Sawyer, Rubyworks |


## Description

Ruby Test is a universal test harness for Ruby test framworks. It defines
a simple specification for compliant test framworks to conform. By doing
so Ruby Test can be used to run the frameworks tests.

## Synopsis

The universal access point for universal testing is the $TEST_SUITE
global variable.

    $TEST_SUITE = []

A test framework need only add compliant test objects to the `$TEST_SUITE` global
array. The Ruby Test Runner will iterate through these objects. If a test object
responds to `#call`, it is run as a test unit. If the test object responds
to `#each` it is iterated over as a testcase. All test objects should respond
to `#to_s` for their descriptions to be used in output.

Some _optional_ interfaces can be used to enable aditional features.

If the return value of `#to_s` is a multi-line string, the first line is
taken to be the _label_ or summary of the test unit or test case, and the 
remaining lines are taken to be additional _detail_. A report format may
only show the details if the verbose command line flag it used.

If a test case responds to `#ordered?`, it indicates if its tests must be run
in order. If false, which is the default, then the test runner can randomize
the order for more rigorous testing. If true, the the tests will always be 
run in the order given. Also, if ordered, a test case's test units cannot be
selected or filtered independent of each other during the test run.

If any test object responds to `#omit?` it indicates if the test unit or case
should be skipped, though it still may be mentioned in the test output.

A test framework may raise a `Pending` exception and a test will be recorded
as a "todo" item. Ruby Test defines `class Pending < Excpetion; end`. A test
framework can also to define this class, if need be.

Any raised excpetion that repsonds to `#assertion?` in the affirmative is taken
to a failed assertion rather than an error.


## Usage

There are a few ways to run tests. There is a command line tool:

    $ ruby-test

There is a 'test/autorun.rb' library script can be loaded which creates an +at_exit+
procedure.

    $ ruby -rtest/autorun

There is also a Rake task.

    require 'test/rake'

A Detroit plugin is in the works and should be availabe soon.


## Requirements

Ruby test uses the [ANSI](http://rubyworks.github.com/ansi) gem for color output.


## Development

Ruby Test is still a "nuby" gem. Please feel OBLIGATED to help improve it ;-)


## License

Copyright (c) 2011 Thomas Sawyer, Rubyworks

Made availabe according to the terms of the <b>FreeBSD license</b>.

See COPYING.rdoc for details.
