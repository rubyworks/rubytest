require_relative 'dotprogress'

module Test::Reporters
  # One status line per result, followed by failure details and totals.
  class Summary < Dotprogress
    LABELS = {
      pass: 'PASS', fail: 'FAIL', error: 'ERROR',
      todo: 'TODO', skip: 'SKIP'
    }.freeze

    def begin_suite(suite)
      @case_path = []
    end

    def begin_case(test_case)
      @case_path << test_case.to_s.lines.first.to_s.strip
    end

    def end_case(test_case)
      @case_path.pop
    end

    def record(result)
      label = result.test.to_s.lines.first.to_s.strip
      path = @case_path.dup
      path.pop if result.kind == :case && path.last == label
      path << label unless label.empty?
      @output.puts "#{LABELS.fetch(result.status).ljust(5)} #{path.join('  ')}"
    end
  end
end
