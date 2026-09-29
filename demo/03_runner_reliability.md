## Runner reliability

RubyTest reports an explicitly requested file that does not exist, rather than
passing an empty run.

    runner = Test::Runner.new(files: ['__rubytest_missing_file__.rb'], format: 'test')
    cleanup_ran = false
    runner.config.after { cleanup_ran = true }
    missing_file = begin
      runner.run
      nil
    rescue ArgumentError => error
      error
    end

    missing_file.class.assert == ArgumentError
    missing_file.message.include?('__rubytest_missing_file__.rb').assert == true
    cleanup_ran.assert == true

An empty suite also has an unsuccessful result.

    empty_runner = Test::Runner.new(suite: [], format: 'test')
    empty_runner.run.assert == false

### Selection and skips

Test descriptions can be matched at the top level and inside cases. A skipped
test that matches the selection is still reported.

    class RunnerProbe
      def initialize(description, skip_reason = nil, &block)
        @description = description
        @skip_reason = skip_reason
        @block = block
      end

      def call
        @block.call
      end

      def skip?
        @skip_reason
      end

      def to_s
        @description
      end
    end

    top = RunnerProbe.new('wanted top') { true }
    other = RunnerProbe.new('other') { true }
    nested = RunnerProbe.new('wanted nested') { true }
    skipped = RunnerProbe.new('wanted skipped', 'later') { raise 'should not run' }

    selected = Test::Runner.new(suite: [top, other, [nested, skipped]],
                                match: ['wanted'], format: 'test')
    selected.run.assert == true
    selected.recorder.summary.counts[:pass].assert == 2
    selected.recorder.summary.counts[:skip].assert == 1

Skipping an entire case is recorded too.

    skipped_case = Class.new(Array) do
      def skip?
        'later'
      end
    end.new
    case_skip_runner = Test::Runner.new(suite: [skipped_case], format: 'test')
    case_skip_runner.run.assert == true
    case_skip_runner.recorder.summary.counts[:skip].assert == 1

### Case errors and cleanup

A case setup error is recorded, and the next test and suite cleanup still run.

    broken_case = Class.new(Array) do
      def call
        raise 'setup failed'
      end
    end.new
    following_test = RunnerProbe.new('following test') { true }
    case_runner = Test::Runner.new(suite: [broken_case, following_test], format: 'test')
    suite_ended = false
    case_runner.after(:suite) { suite_ended = true }

    case_runner.run.assert == false
    case_runner.recorder.summary.counts[:error].assert == 1
    case_runner.recorder.summary.counts[:pass].assert == 1
    suite_ended.assert == true

An assertion failure in a hash reporter records the failure and restores
standard output.

    original_stdout = $stdout
    failing_test = RunnerProbe.new('failing test') { raise Assertion, 'expected failure' }
    failure_runner = Test::Runner.new(suite: [failing_test], format: 'test')

    failure_runner.run.assert == false
    failure_runner.recorder.summary.counts[:fail].assert == 1
    ($stdout.equal?(original_stdout)).assert == true

Global assertionless mode treats a false return as a failure.

    previous_assertionless = Test::Config.assertionless
    begin
      Test::Config.assertionless = true
      false_test = RunnerProbe.new('false result') { false }
      hard_runner = Test::Runner.new(suite: [false_test], format: 'test')
      hard_runner.run.assert == false
      hard_runner.recorder.summary.counts[:fail].assert == 1
    ensure
      Test::Config.assertionless = previous_assertionless
    end

### CLI configuration

The `--config` option accepts an alternate configuration file.

    require 'rubytest/cli'
    cli = Test::CLI.new
    cli.options.parse!(['--config', 'custom-test.rb'])
    cli.config_file.assert == 'custom-test.rb'
