require 'test/reporters/abstract_hash'

module Test::Reporters

  # TAP-Y Reporter
  #
  class Tapy < AbstractHash

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
    def pass(test) #, backtrace=nil)
      puts super(test).to_yaml
    end

    #
    def fail(test, exception)
      puts super(test, exception).to_yaml
    end

    #
    def error(test, exception)
      puts super(test, exception).to_yaml
    end

    #
    def todo(test, exception)
      puts super(test, exception).to_yaml
    end

    #
    def omit(test, exception)
      puts super(test, exception).to_yaml
    end

    #
    def end_suite(suite)
      puts super(suite).to_yaml
      puts "..."
    end

  end

end
