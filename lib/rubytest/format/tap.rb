module Test::Reporters
  # TAP version 13 stream. The plan follows execution so case outcomes count.
  class Tap < Abstract
    def initialize(runner, output: $stdout)
      super(runner)
      @output = output
    end

    def capture_output?
      true
    end

    def begin_suite(suite)
      @index = 0
      @output.puts 'TAP version 13'
    end

    def record(result)
      @index += 1
      label = single_line(result.test.to_s)
      line = "#{[:pass, :skip].include?(result.status) ? 'ok' : 'not ok'} #{@index} - #{label}"
      case result.status
      when :skip
        line << " # SKIP #{single_line(result.reason)}"
      when :todo
        line << " # TODO #{single_line(result.exception&.message)}"
      end
      @output.puts line.rstrip

      if [:fail, :error].include?(result.status)
        result.exceptions.each do |exception|
          diagnostic("#{exception.class}: #{exception.message}")
          diagnostic(exception.backtrace&.first) if exception.backtrace&.first
        end
      end
      result.stdout.each_line { |line| diagnostic("stdout: #{line}") }
      result.stderr.each_line { |line| diagnostic("stderr: #{line}") }
    end

    def finish(summary)
      @output.puts summary.total.zero? ? '1..0 # SKIP No tests were run' : "1..#{summary.total}"
    end

  private

    def single_line(value)
      value.to_s.gsub(/\s+/, ' ').strip.gsub('#', '＃')
    end

    def diagnostic(message)
      message.to_s.each_line { |line| @output.puts "# #{line.chomp}" }
    end
  end
end
