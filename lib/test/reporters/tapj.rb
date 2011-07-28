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
    def start_suite(suite)
      puts super(suite).to_json
    end

    #
    def start_case(test_case)
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
    def finish_suite(suite)
      puts super(suite).to_json
      puts "..."
    end

  end

end
