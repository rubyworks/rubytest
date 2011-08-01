require 'ansi/core'
require 'test/core_ext'
require 'test/code_snippet'

ignore_path   = File.expand_path(File.join(__FILE__, '..', '..', '..'))
ignore_regexp = Regexp.new(Regexp.escape(ignore_path))

RUBY_IGNORE_CALLERS = [] unless defined? RUBY_IGNORE_CALLERS
RUBY_IGNORE_CALLERS << ignore_regexp
RUBY_IGNORE_CALLERS << /bin\/ruby-test/

module Test

  module Reporters

    # Test Reporter Base Class
    class Abstract

      #
      def self.inherited(base)
        registry << base
      end

      #
      def self.registry
        @registry ||= []
      end

      #
      def initialize(runner)
        @runner = runner
        #@source = {}

        # in case start_suite is overridden
        @start_time = Time.now
      end

      #
      attr :runner

      #
      def begin_suite(test_suite)
        @start_time = Time.now
      end

      #
      def begin_case(test_case)
      end

      #
      def begin_test(test)
      end

      #
      def skip_case(test_case)
      end

      #
      def skip_test(test)
      end

      #
      #def test(test)
      #end

      #
      def pass(test)
      end

      #
      def fail(test, exception)
      end

      #
      def error(test, exception)
      end

      #
      def todo(test, exception)
      end

      # Report an omitted unit test.
      def omit(test, exception)
      end

      #
      def end_test(test)
      end

      #
      def end_case(test_case)
      end

      #
      def end_suite(test_suite)
      end

    protected

      def record
        runner.recorder
      end

      # Is coverage information requested?
      #def cover? ; runner.cover? ; end

      # Count up the total number of tests.
      def total_count(suite)
        c = 0
        suite.each do |tc|
          if tc.respond_to?(:each)
            c += total_count(tc)
          else
            c += 1
          end
        end
        return c
      end

      # Common timestamp any reporter can use.
      def timestamp
        seconds = Time.now - @start_time

        "Finished in %.5fs, %.2f tests/s." % [seconds, total/seconds]
      end

      #
      def total
        @total ||= subtotal
      end

      #
      def subtotal
        %w{todo pass fail error omit}.inject(0){ |s,r| s += record[r.to_sym].size; s }
      end

      # Common tally stamp any reporter can use.
      #
      # @todo Add assertion counts (if reasonably possible).
      def tally
        sizes = %w{pass fail error todo omit}.map{ |r| record[r.to_sym].size }
        data  = [total] + sizes

        s = "%s tests: %s passing, %s failures, %s errors, %s pending, %s omissions" % data
        #s += "(#{uncovered_units.size} uncovered, #{undefined_units.size} undefined)" if cover?
        s
      end

      # Remove reference to lemon library from backtrace.
      #
      # @param [Exception] exception
      #   The error that was rasied.
      #
      # @return [Array] filtered backtrace
      #--
      # TODO: Matching `bin/ruby-test` is not robust.
      #++
      def clean_backtrace(exception)
        trace = (Exception === exception ? exception.backtrace : exception)
        return trace if $DEBUG
        trace = trace.reject{ |t| RUBY_IGNORE_CALLERS.any?{ |r| r =~ t }}
        trace = trace.map do |t|
          i = t.index(':in')
          i ? t[0...i] : t
        end
        #if trace.empty?
        #  exception
        #else
        #  exception.set_backtrace(trace) if Exception === exception
        #  exception
        #end
        trace.uniq
      end

      #
      # @return [CodeSnippet] code snippet
      def code(source, line=nil)
        case source
        when Exception, Array
          CodeSnippet.from_backtrace(clean_backtrace(source))
        else
          CodeSnippet.new(source, line)
        end
      end

=begin
      # Have to thank Suraj N. Kurapati for the crux of this code.
      def code_snippet(exception, bredth=2)
        file, line, code, range = code_snippet_parts(exception, bredth)

        # ensure proper alignment by zero-padding line numbers
        format = " %2s %0#{range.last.to_s.length}d %s"

        range.map do |n|
          format % [('=>' if n == line), n, code[n-1].chomp]
        end.join("\n") #.unshift "[#{region.inspect}] in #{source_file}"
      end

      #
      def code_snippet_array(exception, bredth=3)
        file, line, code, range = code_snippet_parts(exception, bredth)
        range.map do |n|
          code[n-1].chomp
        end
      end

      #
      def code_snippet_omap(exception, bredth=3)
        file, line, code, range = code_snippet_parts(exception, bredth)
        a = []
        range.each do |n|
          a << {n => code[n-1].chomp}
        end
        a
      end

      # TODO: improve
      def code_line(exception)
        code_snippet_array(exception, 0).first.strip
      end

      #
      def code_snippet_parts(exception, bredth=3)
        backtrace = clean_backtrace(exception)
        backtrace.first =~ /(.+?):(\d+(?=:|\z))/ or return ""
        source_file, source_line = $1, $2.to_i

        source = source_code(source_file)

        radius = bredth # number of surrounding lines to show
        region = [source_line - radius, 1].max ..
                 [source_line + radius, source.length].min

        return source_file, source_line, source, region
      end

      #
      def source_code(file)
        @source[file] ||= (
          File.readlines(file)
        )
      end
=end

      # TODO: Show more of the file name than just the basename.
      def file_and_line(exception)
        line = clean_backtrace(exception)[0]
        return "" unless line
        i = line.rindex(':in')
        line = i ? line[0...i] : line
        File.basename(line)
      end

      #
      def file_and_line_array(exception)
        case exception
        when Exception
          line = exception.backtrace[0]
        else
          line = exception[0] # backtrace
        end
        return ["", 0] unless line
        i = line.rindex(':in')
        line = i ? line[0...i] : line
        f, l = File.basename(line).split(':')
        return [f, l.to_i]
      end

      #
      def file(exception)
        file_and_line_array(exception).first
      end

      #
      def line(exception)
        file_and_line_array(exception).last
      end

    end

  end

end
