require 'test/reporters/hash'

module Test::Reporters

  # TAP-J Reporter
  #
  class Tapj < HashAbstract

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
    def pass(unit) #, backtrace=nil)
      puts super(unit).to_json
    end

    #
    def fail(unit, exception)
      puts super(unit, exception).to_json
    end

    #
    def error(unit, exception)
      puts super(unit, exception).to_json
    end

    #
    def todo(unit, exception)
      puts super(unit, exception).to_json
    end

    #
    def end_suite(suite)
      puts super(suite).to_json
      puts "..."
    end

  end

end
