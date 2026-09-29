module Test
  # The outcome of one test, or of a case that was skipped or raised an error.
  class Result
    STATUSES = [:pass, :fail, :error, :todo, :skip].freeze
    KINDS = [:test, :case].freeze

    attr_reader :test, :kind, :status, :exception, :exceptions, :reason, :elapsed, :stdout, :stderr

    def initialize(test:, status:, kind: :test, exception: nil, reason: nil,
                   elapsed: 0.0, stdout: '', stderr: '', exceptions: nil)
      raise ArgumentError, "unknown result status: #{status.inspect}" unless STATUSES.include?(status)
      raise ArgumentError, "unknown result kind: #{kind.inspect}" unless KINDS.include?(kind)

      @test = test
      @kind = kind
      @status = status
      @exception = exception
      @exceptions = (exceptions || (exception ? [exception] : [])).dup.freeze
      @reason = reason
      @elapsed = elapsed
      @stdout = stdout.to_s.dup.freeze
      @stderr = stderr.to_s.dup.freeze
      freeze
    end
  end

  # A snapshot of everything recorded during one run.
  class RunSummary
    attr_reader :suite, :results, :counts, :elapsed

    def initialize(suite:, results:, elapsed:)
      @suite = suite
      @results = results.dup.freeze
      @elapsed = elapsed
      @counts = Result::STATUSES.each_with_object({}) do |status, counts|
        counts[status] = @results.count { |result| result.status == status }
      end.freeze
      freeze
    end

    def total
      results.size
    end

    def results_for(status)
      results.select { |result| result.status == status }
    end

    def success?
      counts[:fail].zero? && counts[:error].zero? &&
        (counts[:pass] + counts[:todo] + counts[:skip]).positive?
    end
  end
end
