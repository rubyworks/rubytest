# Ruby Test

[Homepage](http://rubyworks.github.com/test) /
[Development](http://github.com/rubyworks/test) /
[Issues](http://github.com/rubyworks/test/issues)

Ruby Test is a universal test harness for use by any Ruby test framework.
It defines a simple specification for compliance, which allows Ruby Test
to run the framework's tests, and even test across multiple frameworks
in a single pass.

## Specification

### $TEST_SUITE

The universal access point for testing is the $TEST_SUITE global variable.

    $TEST_SUITE = []

A test framework need only add compliant test objects to the `$TEST_SUITE`
global array. Ruby Test will iterate through these objects. If a test object
responds to `#call`, it is run as a test procedure. If it responds to `#each`
it is iterated over as a test case, where each entry goes though the same process.
All test objects must respond to `#to_s` so their description can be used in
test reports.

### Exception#assertion?

Any raised exception that responds to `#assertion?` in the affirmative is taken
to be a failed assertion rather than simply an error. Ruby Test extends the
Exception class to support this method for all exceptions.

### NotImplementedError

A test framework may raise a `NotImplementedError` to have a test recorded
as pending --a _todo_ item to remind the developer of tests that still
need to be written. The `NotImplementedError` is a standard Ruby exception
and a subclass of `ScriptError`.

If the `NotImplmentedError` responds in the affirmative to `#assertion?` then
the test is taken to be a purposeful _omission_, rather than simply pending.

Some <i>*optional*</i> interfaces can be used to enable additional features...

### Multi-line Description

If the return value of `#to_s` is a multi-line string, the first line is
taken to be the _label_ or _summary_ of the test object. The remaining
lines are taken to be additional _detail_. A report format _might_ only
show the detail if the verbose option is set.

### Ordered

A test case that responds to `#ordered?` indicates if its tests must be run
in order. If false, which is the default, then the test runner can randomize
the order for more rigorous testing. But if true, then the tests will always
be run in the order given. Also, if ordered, a case's test units cannot be
selected or filtered independent of one another.

### Type

A test object may provide a `#type`, which can be used to characterize the
type of test case or test unit. For example, RSpec might return `"describe"`
as the type of a test case and `"it"` as the type of a test unit, where as 
Cucumber would use `"Feature"` and `"Scenario"` for test cases and `"Then"`
for test units (depending on choices made by the implementors).

### Subtext

(NOTE: Is there a better name for this?)

A test object can also supply a `#subtext`, which can be used to provide
a descritpion of the _setup_ associated with a test.

### Source Location

If a test object responds to `#source_location` it will be taken to 
identify the file and line in which the the test was defined. The
return value of `#source_location` must be a two-element array of
`[file, line]`.

### Unit

A test object may respond to `#unit` to identify the particular
component of the software being tested. The return value must be the
the full name of a constant, class or module, or a method. Methods
must be represented with fully qualified names, e.g. `FooClass#foo` and
`FooClass.bar` for an instance method and a class method, respectively.

### Tags

A test object can provide `#tags` which must return a one-word string or
array of one-word strings. The test runner can use the tags to limit the
particular tests that are run.

### Skip

If any test object responds to `#skip?` it indicates that the test unit or
test case should be skipped and not tested. It may or may not be mentioned
in the test output depending on the reporter used.


## Usage

There are a few ways to run tests. First, there is a command line tool:

    $ ruby-test

The command line tool takes various options, use `--help` to see them.
Be sure to load in you rtest framework or framework's ruby-test adapter.

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
