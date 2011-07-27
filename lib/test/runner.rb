module Test

  # Runner will need the Recorder and Pending classes.
  if RUBY_VERSION < '1.9'
    require 'test/recorder'
    require 'test/exception'
  else
    require_relative 'recorder'
    require_relative 'exception'
  end

  $TEST_SUITE = [] unless defined?($TEST_SUITE)

  # The Test::Runner class handles the execution of tests.
  #
  class Runner

    # / / / D E F A U L T S / / /

    # Default report is in the old "dot-progress" format.
    DEFAULT_FORMAT = 'dotprogress'

    #
    def self.suite
      $TEST_SUITE
    end

    #
    def self.files
      @files ||= []
    end

    #
    def self.format
      @format || DEFAULT_FORMAT
    end

    #
    def self.format=(format)
      @format = format
    end

    #
    def self.verbose
      @verbose
    end

    #
    def self.verbose=(boolean)
      @verbose = !!boolean
    end

    #
    def self.match
      @match ||= []
    end

    #
    def self.tags
      @tags ||= []
    end

    # / / / A T T R I B U T E S / / /

    # Test suite to run. This is a list of compliant test units and test cases.
    attr :suite

    # Test files to load.
    attr :files

    # Reporter format name, or name fragment, used to look up reporter class.
    attr :format

    #
    def format=(name)
      @format = name.to_s
    end

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

    # New Runner.
    #
    # @param [Array] suite
    #   A list of compliant tests/testcases.
    #
    def initialize(options={}, &block)
      @suite     = options[:suite]  || self.class.suite
      @files     = options[:files]  || self.class.files
      @format    = options[:format] || self.class.format
      @tags      = options[:tags]   || self.class.tags
      @match     = options[:match]  || self.class.match

      block.call(self) if block
    end

    # The reporter to use for ouput.
    attr :reporter

    # Record pass, fail, error, pending and omitted tests.
    attr :recorder

    # Array of observers, typically this just contains the recorder and
    # reporter instances.
    attr :observers

    # Run test suite.
    #
    # @return [Boolean]
    #   That the tests ran without error or failure.
    #
    def run
      files_resolved.each do |file|
        require file
      end

      @reporter  = reporter_load(format)
      @recorder  = Recorder.new
      @observers = [@reporter, @recorder]

      observers.each{ |o| o.start_suite(suite) }
      run_case(suite)
      observers.each{ |o| o.finish_suite(suite) }

      recorder.success?
    end

  private

    # Run a test case.
    #
    def run_case(cases)
      if cases.respond_to?(:skip?) && cases.skip?
        return observers.each{ |o| o.skip_case(cases) }
      end

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
      if test.respond_to?(:skip?) && test.skip?
        return observers.each{ |o| o.skip(test) }
      end

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
          selected << tc
        end
      else
        cases.each do |tc|
          next if tc.respond_to?(:skip?) && tc.skip?
          next if !match.empty? && !match.any?{ |m| m =~ tc.to_s }
          if tc.respond_to?(:tags)
            tc_tags = [tc.tags].flatten.map{ |t| t.to_s }
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

    # Files can be globs and directories which need to be
    # resolved to a list of files.
    #
    def files_resolved
      list = files.flatten
      list = list.map{ |f| Dir[f] }.flatten
      list = list.map{ |f| File.directory?(f) ? Dir[File.join(f, '**/*.rb')] : f }
      list = list.flatten.uniq
      list = list.map{ |f| File.expand_path(f) } 
      list
    end

  end

end
