require_relative 'dotprogress'

module Test::Reporters
  # Show completed results and timing without enumerating the suite in advance.
  class Progress < Dotprogress
    SYMBOLS = {
      pass: '.', fail: 'F', error: 'E', todo: 'P', skip: 'S'
    }.freeze

    def begin_suite(suite)
      @completed = 0
      @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @depth = 0
    end

    def begin_case(test_case)
      @output.puts "#{'  ' * @depth}#{test_case.to_s.lines.first.to_s.strip}"
      @depth += 1
    end

    def end_case(test_case)
      @depth -= 1
    end

    def record(result)
      @completed += 1
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at
      depth = result.kind == :case && @depth.positive? ? @depth - 1 : @depth
      label = "#{'  ' * depth}#{result.test.to_s.lines.first.to_s.strip}"
      @output.puts "%4d  %8.3fs  %8.5fs  %s  %s" % [
        @completed, elapsed, result.elapsed, SYMBOLS.fetch(result.status), label
      ]
    end
  end
end
