# Developer's Notes

The original specification utilized an `Assertion` base class, defined as
`class Assertion < Exception; end`, to distinguish assertion failures from
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

