require 'test/reporters/abstract'

module Test::Reporters

  # Classic TAP Reporter
  #
  # This reporter conforms to v12 of TAP. It could do with some
  # imporvements yet, and eventually upgraded to v13 of standard.
  class Tap < Abstract

    #
    def begin_suite(suite)
      @start_time = Time.now
      @i = 0
      @n = total_count(suite)
      puts "1..#{@n}"
    end

    def begin_test(unit)
      @i += 1
    end

    #
    def pass(unit)
      puts "ok #{@i} - #{unit}"
    end

    #
    def fail(unit, exception)
      puts "not ok #{@i} - #{unit}"
      puts "  FAIL #{exception.class}"
      puts "  #{exception}"
      puts "  #{clean_backtrace(exception)[0]}"
    end

    #
    def error(unit, exception)
      puts "not ok #{@i} - #{unit}"
      puts "  ERROR #{exception.class}"
      puts "  #{exception}"
      puts "  " + clean_backtrace(exception).join("\n        ")
    end

    #
    def todo(unit, exception)
      puts "not ok #{@i} - #{unit}"
      puts "  PENDING"
      puts "  #{clean_backtrace(exception)[1]}"
    end

    #
    def omit(unit, exception)
      puts "ok #{@i} - #{unit}"
      puts "  OMIT"
      puts "  #{clean_backtrace(exception)[1]}"
    end

  end

end

