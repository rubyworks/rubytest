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

TAP-Y and TAP-J carry the same results as structured records: one for the
suite, one for each case and test, and a final tally. TAP-Y is a stream of
YAML documents, TAP-J a line of JSON for each record.

    require 'yaml'
    require 'json'

    readers = {
      'tapy' => lambda { |text| YAML.load_stream(text) },
      'tapj' => lambda { |text| text.lines.map { |line| JSON.parse(line) } }
    }

    readers.each do |format, read|
      success, output, report = render.call(format)
      success.assert == false
      records = read.call(output)

      records.first['type'].assert == 'suite'
      records.first['rev'].assert == 5
      records.last['type'].assert == 'final'
      records.last['counts']['total'].assert == report.total
      records.last['counts']['omit'].assert == 2

      results = records.select { |record| record['status'] }
      results.size.assert == report.total
      results.map { |record| record['status'] }.sort.assert == %w[error fail omit omit pass todo]
      results.select { |record| record['status'] == 'omit' }.map { |record| record['type'] }.sort.assert == %w[case test]
      records.count { |record| record['type'] == 'case' && !record['status'] }.assert == 2
    end

An exception may have no line of backtrace outside the test framework, as
when a framework marks a test pending itself. Its record then has the message
without a source location.

    bare = probe_type.new('bare') do
      error = NotImplementedError.new('not tested')
      error.set_backtrace([])
      raise error
    end

    readers.each do |format, read|
      success, output, report = render.call(format, [bare, passing])
      records = read.call(output)
      records.last['counts']['total'].assert == 2
      record = records.find { |r| r['label'] == 'bare' }
      record['status'].assert == 'todo'
      record['exception']['message'].assert == 'not tested'
      record['exception'].key?('file').assert == false
    end

A TAP-Y stream ends with the YAML end-of-document marker.

    render.call('tapy')[1].lines.last.chomp.assert == '...'

The command line has a shortcut for each.

    require 'rubytest/cli'
    { '-y' => 'tapy', '--tapj' => 'tapj' }.each do |flag, format|
      cli = Test::CLI.new
      cli.options.parse!([flag])
      cli.format.assert == format
    end

The HTML format writes one self-contained document once the run has
finished. Names, messages and captured output are escaped.

    markup = probe_type.new('markup <b>&</b>') { print '<script>'; true }
    html_suite = [Class.new(Array) { def to_s; 'a <case>'; end }.new([markup, failing]),
                  pending, skipped, skipped_case, broken_case]
    success, output, report = render.call('html', html_suite)
    success.assert == false

    output.lines.first.chomp.assert == '<!DOCTYPE html>'
    output.lines.last.chomp.assert == '</html>'
    output.scan('<div class="result ').size.assert == report.total
    output.scan('<section class="case">').size.assert == output.scan('</section>').size
    %w[pass fail error todo skip].each do |status|
      output.include?(%[<div class="result #{status}">]).assert == true
    end

    output.include?('markup &lt;b&gt;&amp;&lt;/b&gt;').assert == true
    output.include?('<h2>a &lt;case&gt;</h2>').assert == true
    output.include?('<pre class="stdout">&lt;script&gt;</pre>').assert == true
    output.include?('<script>').assert == false
    output.include?('Assertion: ').assert == true
    output.include?('6 tests: 1 passing, 1 failures, 1 errors, 1 pending, 2 skipped.').assert == true
