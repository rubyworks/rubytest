require 'test/reporters/hash'

module Test::Reporters

  # TAP-J Reporter
  #
  class Tapj < AbstractHash

    #
    def initialize(runner)
      require 'json'
      super(runner)
    end

    #
    def begin_suite(suite)
      puts super(suite).to_json
    end

    #
    def begin_case(test_case)
      puts super(test_case).to_json
    end

    #
    def pass(test) #, backtrace=nil)
      puts super(test).to_json
    end

    #
    def fail(test, exception)
      puts super(test, exception).to_json
    end

    #
    def error(test, exception)
      puts super(test, exception).to_json
    end

    #
    def todo(test, exception)
      puts super(test, exception).to_json
    end

    #
    def end_suite(suite)
      puts super(suite).to_json
      puts "..."
    end

  end

end
