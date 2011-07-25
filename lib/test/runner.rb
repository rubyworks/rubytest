module Test

  $TEST_SUITE = [] unless defined?($TEST_SUITE)

  # The Test::Runner class handles the execution of tests.
  #
  class Runner

    #
    DEFAULT_REPORT_FORMAT = 'dotprogress'

    # Test suite to run. This is a list of complient of tests and testcases.
    attr :suite

    # Reporter format name, or name fragment, used to look up reporter class.
    attr :format

    # The reporter to use for ouput.
    attr :reporter

    # Record pass, fail, error, pending and omitted tests.
    attr :recorder

    # Array of observers, typically this just contains the recorder and
    # reporter instances.
    attr :observers

    # TODO: need better ways to select and filter out tests.
    # Namespaces option specifies the selection of test cases
    # to run. Is is an array of strings which are matched
    # against the module/class names using #start_wtih?
    #def namespaces
    #  @options[:namespaces] || []
    #end

    # Provide coverage information?
    #attr :coverage
    #  @options[:cover]
    #end

    # New Runner.
    #
    # @param [Array] suite
    #   A list of compliant tests/testcases.
    #
    def initialize(suite, options={})
      @suite     = suite #|| $TESTS
      #@options   = options

      @format    = options[:format] || DEFAULT_REPORT_FORMAT
      @reporter  = reporter_load(format)
      @recorder  = Recorder.new
      @observers = [ @reporter, @recorder ]
    end

    # Ruby test suite.
    #
    # @return [Boolean]
    #   That the tests ran without error or failure.
    #
    def run
      observers.each{ |o| o.start_suite(suite) }
      run_case(suite)
      observers.each{ |o| o.finish_suite(suite) }

      recorder.success?
    end

    # Run a test case.
    #
    # TODO: Filter out exclude namespaces.
    def run_case(cases)
      cases.each do |tc|
        if tc.respond_to?(:call)
          run_test(tc)
        end
        if tc.respond_to?(:each)
          observers.each{ |o| o.start_case(tc) }
          run_case(tc)
          observers.each{ |o| o.finish_case(tc) }
        end
      end
    end

    # Run a test.
    #
    # @param [TestProc] test
    #   The test to run.
    #
    def run_test(test)
      if test.respond_to?(:omit) && test.omit?
        observers.each{ |o| o.omit(test) }
        return
      end

      observers.each{ |o| o.start_test(test) }
      begin
        test.call
        observers.each{ |o| o.pass(test) }
      rescue Pending => exception
        observers.each{ |o| o.pending(test, exception) }
      rescue Exception => exception
        if exception.assertion?
          observers.each{ |o| o.fail(test, exception) }
        else
          observers.each{ |o| o.error(test, exception) }
        end
      end
      observers.each{ |o| o.finish_test(test) }
    end

=begin
    # Iterate over suite's test cases, filtering out unselected cases
    # if any namespaces constraints are provided.
    #
    def each(&block)
      if namespaces.empty?
        suite.each do |test_case|
          block.call(test_case)
        end
      else
        suite.each do |test_case|
          next unless namespaces.any?{ |n| test_case.target.name.start_with?(n) }
          block.call(test_case)
        end
      end
    end
=end

    # Get a reporter instance be name fragment.
    #
    # @return [Reporter::Abstract]
    #   The test reporter instance.
    #
    def reporter_load(format)
      format = DEFAULT_REPORT_FORMAT unless format
      format = format.to_s.downcase
      name   = reporter_list.find{ |r| /^#{format}/ =~ r }

      raise "unsupported report format" unless format

      require "test/reporters/#{name}"
      reporter = Test::Reporters.const_get(name.capitalize)
      reporter.new(self)
    end

    # Returns a list of available report types.
    #
    # @return [Array<String>]
    #   The names of available reporters.
    #
    def reporter_list
      Dir[File.dirname(__FILE__) + '/reporters/*.rb'].map do |rb|
        File.basename(rb).chomp('.rb')
      end
    end

  end

end

# Runner will need the Recorder and Pending classes.
if RUBY_VERSION < '1.9'
  require 'test/recorder'
  require 'test/pending'
  require 'test/exception'
else
  require_relative 'recorder'
  require_relative 'pending'
  require_relative 'exception'
end
