# encoding: UTF-8

module Test::Reporters

  # TAP-Y Reporter
  #
  # Writes the run as a TAP-Y stream (revision 5): a YAML document for
  # the suite, each case, each test and the final tally.
  #
  class Tapy < AbstractHash

    REVISION = 5

    #
    def initialize(runner, output: $stdout)
      require 'yaml'
      super(runner)
      @output = output
    end

    #
    def begin_suite(suite)
      emit super(suite).merge('rev' => REVISION)
    end

    #
    def begin_case(test_case)
      emit super(test_case)
    end

    #
    def pass(test)
      emit super(test)
    end

    #
    def fail(test, exception)
      emit super(test, exception)
    end

    #
    def error(test, exception)
      emit super(test, exception)
    end

    #
    def todo(test, exception)
      emit super(test, exception)
    end

    #
    def skip_test(test, reason=nil)
      emit super(test, reason)
    end

    #
    def skip_case(test_case, reason=nil)
      emit super(test_case, reason)
    end

    #
    def end_suite(suite)
      emit super(suite)
      @output.puts '...'
    end

  private

    # Write one record to the stream.
    def emit(hash)
      @output.puts hash.to_yaml
      hash
    end

  end

end
