require_relative 'dotprogress'

module Test::Reporters
  # Nest case headings and show each result at its place in the suite.
  class Outline < Dotprogress
    SYMBOLS = {
      pass: '.', fail: 'F', error: 'E', todo: 'P', skip: 'S'
    }.freeze

    def begin_suite(suite)
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
      depth = result.kind == :case && @depth.positive? ? @depth - 1 : @depth
      indent = '  ' * depth
      @output.puts "#{indent}#{SYMBOLS.fetch(result.status)} #{result.test.to_s.lines.first.to_s.strip}"
      if [:fail, :error].include?(result.status)
        result.exceptions.each do |exception|
          @output.puts "#{indent}  #{exception.class}: #{exception.message}"
          location = file_and_line(exception)
          @output.puts "#{indent}  #{location}" unless location.empty?
        end
      end
    end

    def end_suite(suite)
      summary = @summary
      @output.puts
      rate = summary.elapsed.zero? ? 0.0 : summary.total / summary.elapsed
      @output.puts "Finished in %.5fs, %.2f tests/s." % [summary.elapsed, rate]
      @output.puts summary.total.zero? ? 'No tests were run.' : tally_for(summary)
    end
  end
end
