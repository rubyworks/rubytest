require 'test/reporters/abstract'

module Test::Reporters

  # Summary Reporter
  class Summary < Abstract

    #
    SEP = '  '

    #
    def begin_suite(suite)
      timer_reset
      @tc = []
    end

    #
    def begin_case(tc)
      @tc << tc.to_s.split("\n").first
    end

    #
    #def report_instance(instance)
    #  puts
    #  puts instance #"== #{concern.description}\n\n" unless concern.description.empty?
    #  #timer_reset
    #end

    #
    #def begin_unit(unit)
    #   context = unit.context
    #   if @instance != context
    #     @context = context
    #     puts
    #     puts "  #{context}"
    #     puts
    #   end
    #end

    #
    def pass(unit)
      print "PASS  ".ansi(:green, :bold)
      e = @tc + [unit.to_s]
      puts e.join(SEP).ansi(:green)
    end

    #
    def fail(unit, exception)
      print "FAIL  ".ansi(:red, :bold)
      e = @tc + [unit.to_s]
      puts e.join(SEP).ansi(:red)
    end

    #
    def error(unit, exception)
      print "ERROR  ".ansi(:red, :bold)
      e = @tc + [unit.to_s]
      puts e.join(SEP).ansi(:red)
    end

    #
    def todo(unit, exception)
      print "TODO  ".ansi(:yellow, :bold)
      e = @tc + [unit.to_s]
      puts e.join(SEP).ansi(:yellow)
    end

    #
    def omit(unit)
      print "OMIT  ".ansi(:cyan, :bold)
      e = @tc + [unit.to_s]
      puts e.join(SEP).ansi(:cyan)
    end

    #
    def skip(unit)
      print "SKIP ".ansi(:blue, :bold)
      e = @tc + [unit.to_s]
      puts e.join(SEP).ansi(:blue)
    end

    #
    def end_case(test_case)
      @tc.pop
    end

    #
    def end_suite(suite)
      puts

      unless record[:pending].empty?
        puts "PENDING:\n\n"
        record[:pending].each do |unit, exception|
          puts "    #{unit}"
          puts "    #{file_and_line(exception)}"
          puts
        end
      end

      unless record[:fail].empty?
        puts "FAILURES:\n\n"
        record[:fail].each do |unit, exception|
          puts "    #{unit}"
          puts "    #{file_and_line(exception)}"
          puts "    #{exception}"
          puts code(exception).to_s
          #puts "    #{exception.backtrace[0]}"
          puts
        end
      end

      unless record[:error].empty?
        puts "ERRORS:\n\n"
        record[:error].each do |unit, exception|
          puts "    #{unit}"
          puts "    #{file_and_line(exception)}"
          puts "    #{exception}"
          puts code(exception).to_s
          #puts "    #{exception.backtrace[0]}"
          puts
        end
      end

      puts timestamp
      puts
      puts tally
    end

  private

    #
    def timer
      secs  = Time.now - @time
      @time = Time.now
      return "%0.5fs" % [secs.to_s]
    end

    #
    def timer_reset
      @time = Time.now
    end

  end

end
