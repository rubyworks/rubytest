# RELEASE HISTORY

## 0.7.0 / 2013-02-18

Version 0.7 is a significant release. The library has been simplified
by spinning-off both the command-line tool and the Rake task as
`rubytest-cli` and `rubytest-rake` respectively. This was done for a
couple of good reasons: a) It focuses the the library on it's core
functionality and b) and it makes the library suitable for becoming
a Ruby standard library, should that ever become a possibility.

Changes:

* Spun off command-line tool as `rubytest-cli`.
* Spun off Rake task as `rubytest-rake`.


## 0.6.1 / 2013-02-16

Configurations can now supply a before and after procedure to be
run right before or right after tests are run. This can be useful
for setting up coverage tools Simplecov, which has to be setup
before the applicable code is required but after all supporting
test infrustructure is required. This release also fixes
the `-c/--config` option, to prevent name clashes between gems and
local config files.

Changes:

* Add before and after config procs.
* Fix -c/--config loading.
* Remove use of DotOpts, it is not good enough yet.
* Move Rake plugin to separate plugin project.


## 0.6.0 / 2013-02-11

This release of Ruby Test takes a hard step back and reconsiders how
to handle configuration from the ground up. Current users of Ruby Test
will probably have to make some adjustments. Our apologies for the extra
work. But the whole thing simply got more complicated than it needed to
be and it was decided that conventional simplicity, with the option 
unconventional complexity, was the best approach.

To make a long story short... There is no default config file anymore.
The `-p/--profile` command line option has been removed; replaced by
a `-c/--config` option which requires a file relative to the working
directory. In addition the configuration API had been changed from `Test.run`
or `Test.configure`, to adopt the common convention, and it no longer takes
a profile name for an argument. `Test.run` still has the same interface as
`Test.configure` but it will now run tests immediately! So be sure to change
that if you used it the past. Lastly, Ruby Test now supports DotOpts out of
the box, so its easier then ever to setup default command line options.

Changes:

* Rename `Test.run` to `Test.configure` and remove profile argument.
* Add new `Test.run` to immediately run tests.
* Add `-c/--config` option for requiring project file.
* Add `-C` and `-R` options for changing directory.
* Add built-in support for DotOpts.
* Deprecate profiles, removing `-p/--profile` cli option.
* Deprecate Test::Runner configuration class methods.


## 0.5.4 / 2013-01-22

This release simply updates configuraiton code to work with RC v0.4.0.

Changes:

* Call RC.configure explicitly.


## 0.5.3 / 2013-01-07

Adjust Config to look for a project's `.index` file for load path, instead
of a `.ruby` file. Also, this will only happen now if configured to do so,
i.e. via the `-a/--autopath` option on the command line.

Changes:

* Fix config.rb to use .index file, instead of .ruby file.
* Automtically prepend $LOAD_PATH only if asked to do so.


## 0.5.2 / 2012-07-20

Courtier was renamed to RC. And the previous release overlooked the requirement
on RC altogether. This release corrects the issue making it optional. 

Changes:

* Make RC an optional requirement.


## 0.5.1 / 2012-04-30

This release adds support for Courtier-based confgiration.
You can now add `config 'rubytest'` entries into a project's
Config.rb file, instead of creating a separate stand-alone
config file just for test configuration.

Changes:

* Adds support for Courtier-based configuration.


## 0.5.0 / 2012-03-22

This release improves the command line interface, the handling of
configuration and provides a mechinism for adding custom test 
observers. The later can be used for things like mock library
verifcation steps.

Changes:

* Make CLI an actual class.
* Refactor configuration file lookup and support Confection.
* Add customizable test observer via new Advice class.


## 0.4.2 / 2012-03-04

Minor release to fix detection of pre-existance of Exception core
extensions.

Changes:

* Fix detection of Exception extension methods.


## 0.4.1 / 2012-02-27

RubyTest doesn't necessarily need to require 'brass' --albeit in the future
that might end up being a dependency. For now we'll leave it aside.

Changes:

* Remove requirement on brass.


## 0.4.0 / 2012-02-25

This release primarily consists of implementation tweaks. The most significant
change is in support of exception priorities, which justify the major verison bump.

Changes:

* Add preliminary support for exception priorities.
* Capture output for TAP-Y/J reporters.


## 0.3.0 / 2011-12-22

Technically this is a fairly minor release that improves backtrace output
and prepares the `LOAD_PATH` automtically if a `.ruby` file is present.
However, it is significant in that the name of the gem has been changed
from `test` to `rubytest`.

Changes:

* Change gem name to `rubytest`.
* Improve backtrace filtering in reporters.
* Setup `LOAD_PATH` based on .ruby file if present.


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

