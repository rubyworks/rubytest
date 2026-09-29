module Test
  # Owns run results and controls when they reach the reporter.
  class Recorder
    attr_reader :results, :reporter, :summary

    def initialize(reporter = nil)
      @reporter = reporter
      @results = []
    end

    def begin_suite(suite)
      @suite = suite
      @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      reporter.begin_suite(suite) if reporter&.respond_to?(:begin_suite)
    end

    def begin_case(test_case)
      reporter.begin_case(test_case) if reporter&.respond_to?(:begin_case)
    end

    def begin_test(test)
      reporter.begin_test(test) if reporter&.respond_to?(:begin_test)
    end

    def capture_output?
      !!(reporter && reporter.respond_to?(:capture_output?) && reporter.capture_output?)
    end

    def record(result)
      @results << result
      reporter.record(result) if reporter
      result
    end

    def end_test(test)
      reporter.end_test(test) if reporter&.respond_to?(:end_test)
    end

    def end_case(test_case)
      reporter.end_case(test_case) if reporter&.respond_to?(:end_case)
    end

    def end_suite(suite)
      @summary = RunSummary.new(suite: suite, results: results, elapsed: elapsed)
      reporter.finish(@summary) if reporter
      @summary
    end

    def success?
      (@summary || RunSummary.new(suite: @suite, results: results, elapsed: elapsed)).success?
    end

  private

    def elapsed
      return 0.0 unless @started_at
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at
    end
  end
end
