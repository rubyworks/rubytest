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

A test framework need only add compliant  test objects to this `$TEST_SUITE` global
array. The Ruby Test runner will iterate through these objects. If a test object
responds to `#call`, it is run as a test. If the test object responds to `#each` it is
iterated over as a testcase. All test objects should respond to `#to_s` for their
descriptions to be used in output.

Some _optional_ interfaces can be used to enable aditional features.

If a test case responds `true` to `#ordered?`, it indicates that its tests must
be run in order (if +false+, which is the default, then the runner can randomize
the order for more rigorous testing).

If any test object responds `true` to `#omit?` it will not be run, but may still
be mentioned in test output.

A test framework may raise a `Pending` exception and a test will be recorded as a
"todo" item. Ruby Test defines `class Pending < Excpetion; end`. If a test framework
wants to use this feature it should probably also to define this class.

Any Excpetion instance that repsonds to `#assertion?` in the affirmative is taken
to a failed assertion rather than an error.


## Usage

There are a few ways to run tests. There is a command line tool:

    $ ruby-test

There is a 'test/autorun.rb' library script can be loaded which creates an +at_exit+
procedure.

    $ ruby -rtest/autorun

There is also a Rake task.

    require 'test/rake'


## License

Copyright (c) 2011 Thomas Sawyer, Rubyworks

Made availabe according to the terms of the <b>FreeBSD license</b>.

See COPYING.rdoc for details.
