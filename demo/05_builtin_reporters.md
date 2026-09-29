## Built-in reporters

The human-readable formats consume the same results, including pending tests
and skipped cases. They can be selected without installing another gem.

    require 'stringio'

    probe_type = Class.new do
      def initialize(label, reason = nil, &action)
        @label, @reason, @action = label, reason, action
      end

      def call
        @action.call
      end

      def skip?
        @reason
      end

      def to_s
        @label
      end
    end

    passing = probe_type.new('passing') { true }
    failing = probe_type.new('failing') { raise Assertion, 'wrong value' }
    pending = probe_type.new('pending') { raise NotImplementedError, 'later' }
    skipped = probe_type.new('skipped', 'not available') { raise 'must not run' }
    skipped_case = Class.new(Array) do
      def skip?; 'case unavailable'; end
      def to_s; 'skipped case'; end
    end.new([passing])
    broken_case = Class.new(Array) do
      def call; raise 'case setup failed'; end
      def to_s; 'broken case'; end
    end.new([passing])
    suite = [[passing, failing], pending, skipped, skipped_case, broken_case]

    render = lambda do |format, tests = suite|
      require "rubytest/format/#{format}"
      output = StringIO.new
      reporter_type = Test::Reporters.const_get(format.capitalize)
      runner_type = Class.new(Test::Runner) do
        define_method(:reporter_load) { |_name| reporter_type.new(self, output: output) }
      end
      runner = runner_type.new(suite: tests, format: format)
      [runner.run, output.string, runner.recorder.summary]
    end

    %w[summary outline progress].each do |format|
      success, output, report = render.call(format)
      success.assert == false
      report.total.assert == 6
      output.include?('failing').assert == true
      output.include?('skipped case').assert == true
      output.include?('6').assert == true
    end

TAP emits one test point for every result. Test output is captured and appears
as diagnostics, so it cannot corrupt the TAP stream. The final plan uses the
number actually recorded, including the broken and skipped cases.

    output_test = probe_type.new('output') { print "ok 999 - injected\n"; true }
    tap_suite = [[output_test, failing], pending, skipped, skipped_case, broken_case]
    success, output, report = render.call('tap', tap_suite)
    success.assert == false
    lines = output.lines.map(&:chomp)
    lines.first.assert == 'TAP version 13'
    lines.last.assert == '1..6'
    lines.grep(/\A(?:ok|not ok) \d+ - /).size.assert == report.total
    lines.grep(/# SKIP /).size.assert == 2
    lines.grep(/# TODO /).size.assert == 1
    lines.grep(/\A# stdout: ok 999 - injected/).size.assert == 1
    lines.grep(/\Anot ok \d+ - broken case/).size.assert == 1
