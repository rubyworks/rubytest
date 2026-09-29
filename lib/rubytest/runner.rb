require 'stringio'

module Test

  # Alias for `Test.configure`.
  # Use #run! to run tests immediately.
  #
  def self.run(profile=nil, &config_proc)
    configure(profile, &config_proc)
  end

  # Configure and run immediately.
  #
  # @todo Should this method return the success instead of exiting?
  # @todo Wrap run in at_exit ?
  #
  # @return [void]
  def self.run!(config=nil, &config_proc)
    begin
      success = Runner.run(config, &config_proc)
      exit -1 unless success
    rescue => error
      raise error if $DEBUG
      $stderr.puts('ERROR: ' + error.to_s)
      exit -1
    end
  end

  # The Test::Runner class handles the execution of tests.
  #
  class Runner

    # Run tests.
    #
    # @param [Config,Hash,String,Symbol] config
    #   Either a Config instance, a hash to construct a Config
    #   instance with, or a name of a configuration profile.
    #
    # @return [Boolean] Success of test run.
    def self.run(config=nil, &config_proc) #:yield:
      runner = Runner.new(config, &config_proc)
      runner.run
    end

    # Exceptions that are not caught by test runner.
    OPEN_ERRORS = [NoMemoryError, SignalException, Interrupt, SystemExit]

    # New Runner.
    #
    # @param [Config] config
    #   Config instance.
    #
    def initialize(config) #:yield:
      @config = case config
        when Config then config
        when Hash   then Config.new(config)
        else Test.configuration(config)
      end

      @config.apply!  # apply lazy config block

      yield(@config) if block_given?

      @advice = Advice.new
    end

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

    # The reporter to use for ouput.
    attr :reporter

    # Record pass, fail, error and pending tests.
    attr :recorder

    # Execution hooks and the reporting pipeline entry point.
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

        config.loadpath.flatten.each{ |path| $LOAD_PATH.unshift(path) }
        config.requires.flatten.each{ |file| require file }

        # Config before advice occurs after loadpath and require are
        # applied and before test files are required.
        config.before.call if config.before

        begin
          test_files.each do |test_file|
            require test_file
          end

          @reporter  = reporter_load(format)
          @recorder  = Recorder.new(@reporter)

          @observers = [advice, @recorder]

          started = false
          begin
            advice.begin_suite(suite)
            recorder.begin_suite(suite)
            started = true
            run_thru(suite)
          ensure
            if started
              begin
                advice.end_suite(suite)
              ensure
                recorder.end_suite(suite)
              end
            end
          end
        ensure
          config.after.call if config.after
        end
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
      select(list).each do |t|
        if t.respond_to?(:each)
          run_case(t)
        elsif t.respond_to?(:call)
          run_test(t)
        else
          raise TypeError, "not a test or test case: #{t.inspect}"
        end
      end
    end

    # Run a test case.
    #
    def run_case(tcase)
      if tcase.respond_to?(:skip?) && (reason = tcase.skip?)
        advice.skip_case(tcase, reason)
        return recorder.record(Result.new(test: tcase, kind: :case,
                                          status: :skip, reason: reason))
      end

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      before_error = nil
      begin
        advice.begin_case(tcase)
      rescue *OPEN_ERRORS
        raise
      rescue Exception => hook_error
        before_error = hook_error
      end
      recorder.begin_case(tcase)

      begin
        if before_error
          raise before_error
        elsif tcase.respond_to?(:call)
          tcase.call do
            run_thru(tcase)
          end
        else
          run_thru(tcase)
        end
      rescue *OPEN_ERRORS
        raise
      rescue Exception => exception
        advice.error(tcase, exception)
        recorder.record(Result.new(test: tcase, kind: :case, status: :error,
                                   exception: exception, elapsed: elapsed_since(started)))
      ensure
        begin
          advice.end_case(tcase)
        rescue *OPEN_ERRORS
          raise
        rescue Exception => exception
          advice.error(tcase, exception)
          recorder.record(Result.new(test: tcase, kind: :case, status: :error,
                                     exception: exception, elapsed: elapsed_since(started)))
        ensure
          recorder.end_case(tcase)
        end
      end
    end

    # Run a test.
    #
    # @param [Object] test
    #   The test to run, must repsond to #call.
    #
    def run_test(test)
      if test.respond_to?(:skip?) && (reason = test.skip?)
        advice.skip_test(test, reason)
        return recorder.record(Result.new(test: test, status: :skip, reason: reason))
      end

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      exceptions = []
      begin
        advice.begin_test(test)
      rescue *OPEN_ERRORS
        raise
      rescue Exception => hook_error
        exceptions << hook_error
      end

      recorder.begin_test(test)
      report_started = true
      capture = recorder.capture_output?
      original_stdout, original_stderr = $stdout, $stderr if capture
      captured_stdout, captured_stderr = StringIO.new, StringIO.new if capture
      begin
        $stdout, $stderr = captured_stdout, captured_stderr if capture
        begin
          if exceptions.empty?
            success = test.call
            raise Assertion, "failure of #{test}" if config.hard? && !success
          end
        rescue *OPEN_ERRORS
          raise
        rescue Exception => error
          exceptions << error
        ensure
          begin
            advice.end_test(test)
          rescue *OPEN_ERRORS
            raise
          rescue Exception => hook_error
            exceptions << hook_error
          end
        end

        status, exception = outcome_for(exceptions)
        begin
          exception ? advice.public_send(status, test, exception) : advice.pass(test)
        rescue *OPEN_ERRORS
          raise
        rescue Exception => hook_error
          exceptions << hook_error
          status, exception = outcome_for(exceptions)
        end
        result = Result.new(test: test, status: status, exception: exception,
                            exceptions: exceptions,
                            elapsed: elapsed_since(started),
                            stdout: captured_stdout&.string,
                            stderr: captured_stderr&.string)
      ensure
        $stdout, $stderr = original_stdout, original_stderr if capture
      end

      recorder.record(result)
    ensure
      recorder.end_test(test) if report_started
    end

    def elapsed_since(started)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    end

    def outcome_for(exceptions)
      return [:pass, nil] if exceptions.empty?

      exception = exceptions.find do |error|
        !(NotImplementedError === error) && !error.assertion?
      end
      exception ||= exceptions.find(&:assertion?)
      exception ||= exceptions.first

      status = if NotImplementedError === exception
        :todo
      else
        exception.assertion? ? :fail : :error
      end
      [status, exception]
    end

    # TODO: Make sure this filtering code is correct for the complex 
    #       condition that that ordered testcases can't have their tests
    #       filtered individually (since they may depend on one another).

    # Filter cases based on selection criteria.
    #
    # @return [Array] selected test cases
    def select(cases)
      return cases if cases.respond_to?(:ordered?) && cases.ordered?
      return cases if config.match.empty? && config.units.empty? && config.tags.empty?

      selected = []
      cases.each do |tc|
        unless tc.respond_to?(:each) || tc.respond_to?(:call)
          raise TypeError, "not a test or test case: #{tc.inspect}"
        end

        # Keep cases so their descendants can be filtered. The case itself
        # may have a different description, unit, or tags from its tests.
        if tc.respond_to?(:each)
          selected << tc
          next
        end

        next if !config.match.empty? && !config.match.any?{ |m| tc.to_s.include?(m) }

        if !config.units.empty?
          next unless tc.respond_to?(:unit)
          next unless config.units.any?{ |u| tc.unit.to_s.start_with?(u) }
        end

        if !config.tags.empty?
          next unless tc.respond_to?(:tags)
          tc_tags = [tc.tags].flatten.map{ |t| t.to_s }
          next if (config.tags & tc_tags).empty?
        end

        selected << tc
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
      name   = reporter_list.find{ |r| r.start_with?(format) } || format

      if KNOWN_FORMATS.include?(name)
        require_relative "format/#{name}"
      else
        begin
          require "rubytest/format/#{name}"
        rescue LoadError => error
          raise ArgumentError, "unknown report format #{name.inspect}" if error.path == "rubytest/format/#{name}"
          raise
        end
      end

      reporter = Test::Reporters.const_get(name.capitalize)
      reporter = reporter.new(self)
      unless reporter.respond_to?(:record) && reporter.respond_to?(:finish)
        raise ArgumentError, "report format #{name} does not support result reporting"
      end
      reporter
    end

    # List of known report formats.
    #
    # TODO: Could use finder gem to look these up, but that's yet another dependency.
    #
    KNOWN_FORMATS = %w{
      dotprogress progress outline summary tap test
    }

    # Returns a list of available report types.
    #
    # @return [Array<String>]
    #   The names of available reporters.
    def reporter_list
      return KNOWN_FORMATS.sort
      #list = Dir[File.dirname(__FILE__) + '/reporters/*.rb']
      #list = list.map{ |r| File.basename(r).chomp('.rb') }
      #list = list.reject{ |r| /^abstract/ =~ r }
      #list.sort
    end

    # Files can be globs and directories which need to be
    # resolved to a list of files.
    #
    # @return [Array<String>]
    def resolve_test_files
      config.files.flatten.flat_map do |pattern|
        files = Dir[pattern].flat_map do |file|
          File.directory?(file) ? Dir[File.join(file, '**/*.rb')] : [file]
        end
        raise ArgumentError, "no test files match #{pattern.inspect}" if files.empty?
        files
      end.uniq.map{ |file| File.expand_path(file) }
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
