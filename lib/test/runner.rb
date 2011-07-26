module Test

  $TEST_SUITE = [] unless defined?($TEST_SUITE)

  # The Test::Runner class handles the execution of tests.
  #
  class Runner

    # Default report is in the old "dot-progress" format.
    DEFAULT_REPORT_FORMAT = 'dotprogress'

    # Test suite to run. This is a list of complient of tests and testcases.
    attr :suite

    # Reporter format name, or name fragment, used to look up reporter class.
    attr :format

    # Matching text used to filter which tests are run.
    attr :match

    # Selected tags used to filter which tests are run.
    attr :tags

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

    # The reporter to use for ouput.
    attr :reporter

    # Record pass, fail, error, pending and omitted tests.
    attr :recorder

    # Array of observers, typically this just contains the recorder and
    # reporter instances.
    attr :observers

    # New Runner.
    #
    # @param [Array] suite
    #   A list of compliant tests/testcases.
    #
    def initialize(suite, options={})
      @suite     = suite #|| $TESTS
      #@options   = options

      @format    = options[:format] || DEFAULT_REPORT_FORMAT
      @match     = options[:match]
      @tags      = options[:tags]

      @reporter  = reporter_load(format)
      @recorder  = Recorder.new
      @observers = [ @reporter, @recorder ]
    end

    # Run test suite.
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
    def run_case(cases)
      select(cases).each do |tc|
        if tc.respond_to?(:call)
          run_test(tc)
        end
        if tc.respond_to?(:each)
          observers.start_case(tc)
          run_case(tc)
          observers.finish_case(tc)
        end
      end
    end

    # Run a test unit.
    #
    # @param [TestProc] test
    #   The test to run.
    #
    def run_test(test)
      #if test.respond_to?(:skip?) && test.skip?
      #  return observers.each{ |o| o.skip(test) }
      #end
      observers.each{ |o| o.start_test(test) }
      begin
        test.call
        observers.each{ |o| o.pass(test) }
      rescue NotImplementedError => exception
        if exception.assertion?
          observers.each{ |o| o.omit(test, exception) }
        else
          observers.each{ |o| o.todo(test, exception) }
        end
      rescue Exception => exception
        if exception.assertion?
          observers.each{ |o| o.fail(test, exception) }
        else
          observers.each{ |o| o.error(test, exception) }
        end
      end
      observers.each{ |o| o.finish_test(test) }
    end

    # TODO: Make sure this filtering code is correct for the complex 
    #       condition that that ordered testcases can't have their tests
    #       filtered individually (since they may depend on one another).

    # Filter cases based on selection criteria.
    #
    # @return [Array] selected test cases
    def select(cases)
      selected = []
      if cases.respond_to?(:ordered?) && cases.ordered?
        cases.each do |tc|
          next if tc.respond_to?(:skip?) && tc.skip?
          selected << tc
        end
      else
        cases.each do |tc|
          next if tc.respond_to?(:skip?) && tc.skip?
          next if match && match !~ tc.to_s
          if tc.respond_to?(:tags)
            tc_tags = [tc.tags].flatten
            next if (tags & tc_tags).empty?
          end
          selected << tc
        end
      end
      selected
    end

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

  #
  class Selection
    def initialize(test_object)
      @test_object
    end
    def call
      @test_object.call
    end
    def each(&block)
      @test_object.each(&block)
    end
    def to_s
      @test_object.to_s
    end
    def subtext
      @test_object.subtext
    end
    # any others?
  end

end

# Runner will need the Recorder and Pending classes.
if RUBY_VERSION < '1.9'
  require 'test/recorder'
  require 'test/exception'
else
  require_relative 'recorder'
  require_relative 'exception'
end
