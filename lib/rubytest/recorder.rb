module Test
  # Owns run results and controls when they reach the reporter.
  class Recorder
    attr_reader :results, :reporter, :summary

    def initialize(reporter = nil)
      @reporter = reporter
      @results = []
      @table = Hash.new { |hash, key| hash[key] = [] }
    end

    # Keep the historical status-indexed view for callers and older reporters.
    def [](key)
      @table[key.to_sym]
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
      case result.status
      when :pass
        self[:pass] << result.test
      when :skip
        self[:skip] << [result.test, result.reason]
      else
        self[result.status] << [result.test, result.exception]
      end

      return result unless reporter

      if native_reporter?
        reporter.record(result)
      else
        report_legacy_result(result)
      end
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
      if reporter
        if native_reporter?
          reporter.finish(@summary)
        else
          reporter.end_suite(suite)
        end
      end
      @summary
    end

    def success?
      (@summary || RunSummary.new(suite: @suite, results: results, elapsed: elapsed)).success?
    end

    # Compatibility for code that sent status callbacks to the recorder.
    def pass(test)
      record(Result.new(test: test, status: :pass))
    end

    def fail(test, exception)
      record(Result.new(test: test, status: :fail, exception: exception))
    end

    def error(test, exception)
      record(Result.new(test: test, status: :error, exception: exception))
    end

    def todo(test, exception)
      record(Result.new(test: test, status: :todo, exception: exception))
    end

    def skip_test(test, reason)
      record(Result.new(test: test, status: :skip, reason: reason))
    end

    def skip_case(test_case, reason)
      record(Result.new(test: test_case, kind: :case, status: :skip, reason: reason))
    end

  private

    def native_reporter?
      reporter.respond_to?(:record) && reporter.respond_to?(:finish)
    end

    def elapsed
      return 0.0 unless @started_at
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at
    end

    def report_legacy_result(result)
      if result.status == :skip
        method = result.kind == :case ? :skip_case : :skip_test
        reporter.public_send(method, result.test, result.reason)
      elsif result.status == :pass
        reporter.pass(result.test)
      else
        reporter.public_send(result.status, result.test, result.exception)
      end
    end
  end
end
