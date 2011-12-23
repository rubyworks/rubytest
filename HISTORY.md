# RELEASE HISTORY

## 0.3.0 / 2011-12-22

Except for the fact than the gem has been renamed to `ruby-test` (rather
than the previous `test`), this is a minor release that improves backtrace
output and prepares the LOAD_PATH automtically if a .ruby file is present.

Changes:

* Rename gem to `ruby-test`.
* Improve backtrace results in reporters.
* Setup LOAD_PATH based on .ruby file if present.


## 0.2.0 / 2011-08-10

With this release Ruby Test is essentially feature complete. Of course there
are plenty of tweaks and improvements yet to come, but Ruby Test is fully usable
at this point. Only one major aspect of the design remains in question --the
way per-testcase "before and after all" advice is handled. Other than that
the API fairly solid, even as this early state of development. Always helps
when you have a spec to go by!

Changes:

* Use Config class to look-up .test file.
* Support hard testing, topic and pre-case setup.
* Add autorun.rb runner script.
* Add a test reporter to use for testing Ruby Test itself.
* Improved dotprogess reporter's handling of omissions.
* Add unit selection to test runner.


## 0.1.0 / 2011-07-30

First release of Ruby Test.

Changes:

* It's Your Birthday!

