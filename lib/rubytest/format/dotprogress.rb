# encoding: UTF-8

module Test::Reporters

  # Simple Dot-Progress Reporter
  class Dotprogress < Abstract

    def initialize(runner, output: $stdout)
      super(runner)
      @output = output
      @verbose = runner.verbose?
    end

    def record(result = nil)
      return super() unless result # historical access to runner.recorder

      if result.status == :skip
        method = result.kind == :case ? :skip_case : :skip_test
        public_send(method, result.test, result.reason)
      elsif result.status == :pass
        pass(result.test)
      else
        public_send(result.status, result.test, result.exception)
      end
    end

    def finish(summary)
      @summary = summary
      end_suite(summary.suite)
    end

    # Keep the old callbacks useful to subclasses of this reporter.
    def skip_test(test, reason)
      emit('S'.ansi(:cyan)) if @verbose
    end

    def pass(test)
      emit('.')
    end

    def fail(test, exception)
      emit('F'.ansi(:red))
    end

    def error(test, exception)
      emit('E'.ansi(:red, :bold))
    end

    def todo(test, exception)
      emit('P'.ansi(:yellow))
    end

    def end_suite(suite)
      summary = @summary
      @output.puts
      @output.puts
      rate = summary.elapsed.zero? ? 0.0 : summary.total / summary.elapsed
      @output.puts "Finished in %.5fs, %.2f tests/s." % [summary.elapsed, rate]
      @output.puts

      if @verbose && summary.counts[:skip].positive?
        @output.puts "SKIPPED\n\n"
        summary.results_for(:skip).each do |result|
          @output.puts "    #{result.test}".ansi(:bold)
          @output.puts "    #{result.reason}" if String === result.reason
          @output.puts
        end
      end

      {todo: 'PENDING', fail: 'FAILURES', error: 'ERRORS'}.each do |status, title|
        next if summary.counts[status].zero?
        @output.puts "#{title}\n\n"
        summary.results_for(status).each do |result|
          exception = result.exception
          @output.puts "    #{result.test}".ansi(:bold) unless status == :todo && result.test.to_s.empty?
          @output.puts "    #{exception}"
          @output.puts "    #{file_and_line(exception)}"
          @output.puts code(exception)
          @output.puts "    " + clean_backtrace(exception).join("\n    ") unless status == :todo
          @output.puts
        end
      end

      if summary.total.zero?
        @output.puts 'No tests were run.'
      else
        @output.puts tally_for(summary)
      end
    end

  private

    def emit(symbol)
      @output.print(symbol)
      @output.flush
    end

    def tally_for(summary)
      items = [:pass, :error, :fail, :todo, :skip].filter_map do |status|
        count = summary.counts[status]
        next if count.zero?
        title = TITLES[status].downcase
        percentage = @verbose ? " (%.1f%%)" % (count.to_f / summary.total * 100) : ''
        "#{count.to_s.ansi(:bold)} #{title}#{percentage}"
      end
      "Executed #{summary.total.to_s.ansi(:bold)} tests with #{items.join(', ')}."
    end

  end

end
