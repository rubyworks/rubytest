## Result pipeline

The runner sends completed outcomes to the recorder. The recorder keeps them
and forwards the same result objects, along with case boundaries, to a reporter.

    events = []
    reporter = Object.new
    reporter.define_singleton_method(:begin_suite) { |suite| events << :begin_suite }
    reporter.define_singleton_method(:begin_case) { |tcase| events << :begin_case }
    reporter.define_singleton_method(:begin_test) { |test| events << :begin_test }
    reporter.define_singleton_method(:record) { |result| events << result }
    reporter.define_singleton_method(:end_test) { |test| events << :end_test }
    reporter.define_singleton_method(:end_case) { |tcase| events << :end_case }
    reporter.define_singleton_method(:finish) { |summary| events << summary }

    runner_type = Class.new(Test::Runner) do
      define_method(:reporter_load) { |_format| reporter }
    end

    passing = -> { true }
    failing = -> { raise Assertion, 'no' }
    broken = -> { raise 'unexpected' }
    pending = -> { raise NotImplementedError, 'later' }
    skipped = -> { raise 'must not run' }
    skipped.define_singleton_method(:skip?) { 'later' }

    skipped_case = [-> { raise 'must not run' }]
    skipped_case.define_singleton_method(:skip?) { 'case later' }
    broken_case = Class.new(Array) do
      def call
        raise 'case setup failed'
      end
    end.new

    runner = runner_type.new(suite: [[passing, failing], broken, pending, skipped,
                                     skipped_case, broken_case], format: 'test')
    runner.run.assert == false

    statuses = runner.recorder.results.map(&:status)
    statuses.assert == [:pass, :fail, :error, :todo, :skip, :skip, :error]
    runner.recorder.results.map(&:kind).assert ==
      [:test, :test, :test, :test, :test, :case, :case]
    runner.recorder[:fail].first.first.assert.equal? failing
    runner.recorder[:skip].size.assert == 2
    events.grep(Test::Result).map(&:object_id).assert ==
      runner.recorder.results.map(&:object_id)
    events.count(:begin_case).assert == 2
    events.count(:end_case).assert == 2
    summary = events.last
    summary.class.assert == Test::RunSummary
    summary.counts[:error].assert == 2
    summary.success?.assert == false

An after hook can turn an otherwise passing test into a failed result before
that result is recorded.

    hook_reporter = Object.new
    hook_reporter.define_singleton_method(:record) { |result| }
    hook_reporter.define_singleton_method(:finish) { |summary| }
    hook_runner_type = Class.new(Test::Runner) do
      define_method(:reporter_load) { |_format| hook_reporter }
    end
    hook_runner = hook_runner_type.new(suite: [-> { true }], format: 'test')
    hook_runner.after(:test) { raise Assertion, 'verification failed' }
    hook_runner.run.assert == false
    hook_runner.recorder.results.first.status.assert == :fail
    hook_runner.recorder.results.first.exception.message.include?('verification failed').assert == true

A failing before hook is recorded as an error; the test body is not called,
and the after hook still runs.

    calls = 0
    cleanup_ran = false
    before_runner = hook_runner_type.new(suite: [-> { calls += 1 }], format: 'test')
    before_runner.before(:test) { raise 'setup failed' }
    before_runner.after(:test) { cleanup_ran = true }
    before_runner.run.assert == false
    before_runner.recorder.results.first.status.assert == :error
    calls.assert == 0
    cleanup_ran.assert == true

A case after hook error is recorded after its child test and case reporting
still ends.

    case_end_events = []
    case_end_reporter = Object.new
    case_end_reporter.define_singleton_method(:record) { |result| case_end_events << result.status }
    case_end_reporter.define_singleton_method(:end_case) { |tcase| case_end_events << :end_case }
    case_end_reporter.define_singleton_method(:finish) { |summary| }
    case_end_runner_type = Class.new(Test::Runner) do
      define_method(:reporter_load) { |_format| case_end_reporter }
    end
    case_end_runner = case_end_runner_type.new(suite: [[-> { true }]], format: 'test')
    case_end_runner.after(:case) { raise 'case teardown failed' }
    case_end_runner.run.assert == false
    case_end_events.assert == [:pass, :error, :end_case]

    case_end_events.clear
    case_body_calls = 0
    case_cleanup_ran = false
    case_start_runner = case_end_runner_type.new(suite: [[-> { case_body_calls += 1 }]], format: 'test')
    case_start_runner.before(:case) { raise 'case setup failed' }
    case_start_runner.after(:case) { case_cleanup_ran = true }
    case_start_runner.run.assert == false
    case_end_events.assert == [:error, :end_case]
    case_body_calls.assert == 0
    case_cleanup_ran.assert == true

Reporters that still use the old status callbacks work through the Recorder.

    legacy_events = []
    legacy_reporter = Object.new
    legacy_reporter.define_singleton_method(:pass) { |test| legacy_events << [:pass, test] }
    legacy_reporter.define_singleton_method(:end_suite) { |suite| legacy_events << [:end_suite, suite] }
    legacy_recorder = Test::Recorder.new(legacy_reporter)
    legacy_suite = []
    legacy_recorder.begin_suite(legacy_suite)
    legacy_result = Test::Result.new(test: passing, status: :pass)
    legacy_recorder.record(legacy_result)
    legacy_recorder.end_suite(legacy_suite)
    legacy_events.assert == [[:pass, passing], [:end_suite, legacy_suite]]
    legacy_recorder.results.first.assert.equal? legacy_result

The hash reporter receives captured output in its result, and the runner
restores the process streams after execution.

    require 'rubytest/format/test'
    hash_reporter_type = Class.new(Test::Reporters::Test) do
      attr_reader :rows

      def initialize(runner)
        super
        @rows = []
      end

      def record(result)
        @rows << super
      end
    end
    hash_runner_type = Class.new(Test::Runner) do
      define_method(:reporter_load) { |_format| hash_reporter_type.new(self) }
    end
    original_stdout, original_stderr = $stdout, $stderr
    output_runner = hash_runner_type.new(suite: [-> { print 'hello'; warn 'oops' }], format: 'test')
    output_runner.upon(:pass) { print ' from hook' }
    output_runner.run.assert == true
    row = output_runner.reporter.rows.first
    row['stdout'].assert == 'hello from hook'
    row['stderr'].assert == "oops\n"
    ($stdout.equal?(original_stdout)).assert == true
    ($stderr.equal?(original_stderr)).assert == true
