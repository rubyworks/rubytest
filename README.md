# Ruby Test

<table>
<tr><td>*Author*</td><td>Thomas Sawyer</td></tr>
<tr><td>*License*</td><td>FreeBSD</td></tr>
<tr><td>*Copyright*</td><td>(c) 2011 Thomas Sawyer, Rubyworks</td></tr>
</table>


## Description

Ruby Test is a universal test harness for Ruby test frameworks. It defines
a simple specification for compliant test frameworks to adhear. By doing
so Ruby Test can be used to run the framework's tests, and even test across
multiple frameworks in one go.


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

A test case that responds to `#ordered?` indicates if its tests must be run
in order. If false, which is the default, then the test runner can randomize
the order for more rigorous testing. But if true, then the tests will always be
run in the order given. Also, if ordered, a test case's test units cannot be
selected or filtered independent of one another.

If the return value of `#to_s` is a multi-line string, the first line is
taken to be the _label_ or _summary_ of the test object. The remaining
lines are taken to be additional _detail_. A report format may only show
the details if the verbose command line flag it used.

A test object can also supply a `#subtext`, which can be used to describe
the _setup_ associated with a test. [NOTE: A test framework will not use
this if it only supports one setup per context (the testcase). In that
case the context and subtext effectively share a single description.]

A test object can provide `#tags` which must return a one-word string or
array of one-word strings. The test runner can use the tags to limit the
particular tests that are run.

Likewise a test object may respond to `#covers` to identify the particular
"component" of the program being tested. The return value must be the
the fullname of a constant, class, module or method. Methods must also be
represented with fully qualified names, e.g. `FooClass#foo` and `FooClass.bar`
for an instance method and a class method, respectively.

If any test object responds to `#skip?` it indicates that the test unit or
test case should be skipped and not tested (it may or may not be mentioned
in the test output, as being skipped, depending on the reporter used).

A test framework may raise a `NotImplementedError` to have a test recorded
as "pending" --a sort of "todo" item to remind the developer of tests
that still need to be written. The `NotImplementedError` is a standard Ruby
exception and a subclass of `ScriptError`.

If the `NotImplmentedError` responds in the affirmative to `#assertion?` then
the test is taken to be a purposeful omission, rather than simply pending.

Any raised exception that responds to `#assertion?` in the affirmative is taken
to a failed assertion rather than an error. Ruby Test extends the Extension
class to support this method for all exceptions.


## Considerations

The original specification utlized an `Assertion` base class, defined as
`class Assertion < Excpetion; end`, to distinguish assertion failures from
regular exceptions. All test frameworks (AFAIK) have some variation of this
class, e.g. Test::Unit has `FailureError`. For this to work, it would be
necessary for all such classes to inherit from the common `Assertion` class.
While likely not difficult to implement, it was determined that utilizing a
common `#assertion` method was more flexible and easier for test frameworks
to support.

Test/Unit provides for _notifications_. Support for notifications is something
to consider for a future version.

Feedback on any of these consideration is greatly appreciated. Just
post up an new [issue](http://rubyworks.github/test/issues).


## Usage

There are a few ways to run tests. There is a command line tool:

    $ ruby-test

There is a 'test/autorun.rb' library script can be loaded which creates an +at_exit+
procedure.

    $ ruby -rtest/autorun

There is also a Rake task.

    require 'test/rake'

A Detroit plugin is in the works and should be availabe soon.


## Installation

    $ gem install test


## Requirements

Ruby test uses the [ANSI](http://rubyworks.github.com/ansi) gem for color output.

Ruby Facets is also required for formating methods, in particular, String#tabto.

Becuase of the "fondational" nature of this library we will work on removing
these dependecies for future versions, but for early development these
requirements do their job and do it well.


## Development

Ruby Test is still a "nuby" gem. Please feel OBLIGATED to help improve it ;-)


## License

Copyright (c) 2011 Thomas Sawyer, Rubyworks

Made availabe according to the terms of the <b>FreeBSD license</b>.

See COPYING.rdoc for details.
