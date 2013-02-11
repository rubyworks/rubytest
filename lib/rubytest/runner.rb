module Test

  # Currently this is an alias for configure, however it is likely
  # to become an alias for `Runner.run` in the future.
  #
  # @deprecated Will probably change behavior in future.
  def self.run(config=nil, &config_proc)
    $stderr.puts "configuration profiles no longer supported." if config
    configure(&config_proc)
  end

  # The Test::Runner class handles the execution of tests.
  #
  class Runner

    # TODO: Wrap run in at_exit ?
    def self.run(config=nil, &config_proc)
      runner = Runner.new(config, &config_proc)
      begin
        success = runner.run
        exit -1 unless success
      rescue => error
        raise error if $DEBUG
        $stderr.puts('ERROR: ' + error.to_s)
        exit -1
      end
    end

    # Default report is in the old "dot-progress" format.
    #DEFAULT_FORMAT = 'dotprogress'

    # Exceptions that are not caught by test runner.
    OPEN_ERRORS = [NoMemoryError, SignalException, Interrupt, SystemExit]

    # Handle all configuration via the config instance.
    attr :config

    # Test suite to run. This is a list of compliant test units and test cases.
    def suite
      config.suite
    end

    #
    # TODO: Cache or not?
    #
    def test_files
      #@test_files ||= resolve_test_files
      resolve_test_files
    end

    # Reporter format name, or name fragment, used to look up reporter class.
    def format
      config.format
    end

    # Show extra details in reports.
    def verbose?
      config.verbose?
    end

    # Instance of Advice is a special customizable observer.
    def advice
      @advice
    end

    # Define universal before advice.
    def before(type, &block)
      advice.join_before(type, &block)
    end

    # Define universal after advice. Can be used by mock libraries,
    # for example to run mock verification.
    def after(type, &block)
      advice.join_after(type, &block)
    end

    # Define universal upon advice.
    #
    # See {Advice} for valid join-points.
    def upon(type, &block)
      advice.join(type, &block)
    end

    # New Runner.
    #
    # @param [Config] config
    #   Config instance.
    #
    def initialize(config=nil, &block)
      case config
      when Hash
        @config = Config.new(config)
      else
        @config = config || Test.configuration
      end

      block.call(@config) if block

      #@verbose   = @config.verbose

      @advice = Advice.new
    end

    # The reporter to use for ouput.
    attr :reporter

    # Record pass, fail, error and pending tests.
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
      cd_chdir do
        Test::Config.load_path_setup if config.autopath?

        ignore_callers

        config.loadpath.each{ |path| $LOAD_PATH.unshift(path) }
        config.requires.each{ |file| require file }

        test_files.each do |test_file|
          require test_file
        end

        @reporter  = reporter_load(format)
        @recorder  = Recorder.new

        @observers = [advice, @recorder, @reporter]

        observers.each{ |o| o.begin_suite(suite) }
        run_thru(suite)
        observers.each{ |o| o.end_suite(suite) }
      end

      recorder.success?
    end

  private

    # Add to $RUBY_IGNORE_CALLERS.
    #
    # @todo Improve on this!
    def ignore_callers
      ignore_path   = File.expand_path(File.join(__FILE__, '../../..'))
      ignore_regexp = Regexp.new(Regexp.escape(ignore_path))

      $RUBY_IGNORE_CALLERS ||= {}
      $RUBY_IGNORE_CALLERS << ignore_regexp
      $RUBY_IGNORE_CALLERS << /bin\/rubytest/
    end

    #
    def run_thru(list)
      list.each do |t|
        if t.respond_to?(:each)
          run_case(t)
        elsif t.respond_to?(:call)
          run_test(t)
        else
          #run_note(t) ?
        end
      end
    end

    # Run a test case.
    #
    def run_case(tcase)
      if tcase.respond_to?(:skip?) && (reason = tcase.skip?)
        return observers.each{ |o| o.skip_case(tcase, reason) }
      end

      observers.each{ |o| o.begin_case(tcase) }

      if tcase.respond_to?(:call)
        tcase.call do
          run_thru( select(tcase) )
        end
      else
        run_thru( select(tcase) )
      end

      observers.each{ |o| o.end_case(tcase) }
    end

    # Run a test.
    #
    # @param [Object] test
    #   The test to run, must repsond to #call.
    #
    def run_test(test)
      if test.respond_to?(:skip?) && (reason = test.skip?)
        return observers.each{ |o| o.skip_test(test, reason) }
      end

      observers.each{ |o| o.begin_test(test) }
      begin
        success = test.call
        if config.hard? && !success  # TODO: separate run_test method to speed things up?
          raise Assertion, "failure of #{test}"
        else
          observers.each{ |o| o.pass(test) }
        end
      rescue *OPEN_ERRORS => exception
        raise exception
      rescue NotImplementedError => exception
        #if exception.assertion?  # TODO: May require assertion? for todo in future
          observers.each{ |o| o.todo(test, exception) }
        #else
        #  observers.each{ |o| o.error(test, exception) }
        #end
      rescue Exception => exception
        if exception.assertion?
          observers.each{ |o| o.fail(test, exception) }
        else
          observers.each{ |o| o.error(test, exception) }
        end
      end
      observers.each{ |o| o.end_test(test) }
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
          next if !config.match.empty? && !config.match.any?{ |m| m =~ tc.to_s }

          if !config.units.empty?
            next unless tc.respond_to?(:unit)
            next unless config.units.find{ |u| tc.unit.start_with?(u) }
          end

          if !config.tags.empty?
            next unless tc.respond_to?(:tags)
            tc_tags = [tc.tags].flatten.map{ |t| t.to_s }
            next if (config.tags & tc_tags).empty?
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
    def reporter_load(format)
      format = DEFAULT_REPORT_FORMAT unless format
      format = format.to_s.downcase
      name   = reporter_list.find{ |r| /^#{format}/ =~ r }

      raise "unsupported report format" unless format

      if RUBY_VERSION < '1.9'
        require "rubytest/reporters/#{name}"
      else
        require_relative "reporters/#{name}"
      end

      reporter = Test::Reporters.const_get(name.capitalize)
      reporter.new(self)
    end

    # Returns a list of available report types.
    #
    # @return [Array<String>]
    #   The names of available reporters.
    def reporter_list
      list = Dir[File.dirname(__FILE__) + '/reporters/*.rb']
      list = list.map{ |r| File.basename(r).chomp('.rb') }
      list = list.reject{ |r| /^abstract/ =~ r }
      list.sort
    end

    # Files can be globs and directories which need to be
    # resolved to a list of files.
    #
    # @return [Array<String>]
    def resolve_test_files
      list = config.files.flatten
      list = list.map{ |f| Dir[f] }.flatten
      list = list.map{ |f| File.directory?(f) ? Dir[File.join(f, '**/*.rb')] : f }
      list = list.flatten.uniq
      list = list.map{ |f| File.expand_path(f) } 
      list
    end

    # Change to directory and run block.
    #
    # @raise [Errno::ENOENT] If directory does not exist.
    def cd_chdir(&block)
      if dir = config.chdir
        unless File.directory?(dir)
          raise Errno::ENOENT, "change directory doesn't exist -- `#{dir}'"
        end
        Dir.chdir(dir, &block)
      else
        block.call
      end
    end

  end

end
