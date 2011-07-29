require 'test/reporters/hash'

module Test::Reporters

  # TAP-Y Reporter
  #
  class Tapy < HashAbstract

    #
    def initialize(runner)
      require 'json'
      super(runner)
    end

    #
    def begin_suite(suite)
      puts super(suite).to_yaml
    end

    #
    def begin_case(test_case)
      puts super(test_case).to_yaml
    end

    #
    def pass(unit) #, backtrace=nil)
      puts super(unit).to_yaml
    end

    #
    def fail(unit, exception)
      puts super(unit, exception).to_yaml
    end

    #
    def error(unit, exception)
      puts super(unit, exception).to_yaml
    end

    #
    def todo(unit, exception)
      puts super(unit, exception).to_yaml
    end

    #
    def end_suite(suite)
      puts super(suite).to_yaml
      puts "..."
    end

  end

end
