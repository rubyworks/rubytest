require 'test/reporters/abstract'

module Test::Reporters

  # Simple Dot-Progress Reporter
  class Dotprogress < Abstract

    def omit(unit)
      print "O"
      $stdout.flush
    end

    def pass(unit)
      print "."
      $stdout.flush
    end

    def fail(unit, exception)
      print "F".ansi(:red)
      $stdout.flush
    end

    def error(unit, exception)
      print "E".ansi(:red, :bold)
      $stdout.flush
    end

    def todo(unit, exception)
      print "P".ansi(:yellow)
      $stdout.flush
    end

    def omit(unit, exception)
      print "O".ansi(:cyan)
      $stdout.flush
    end

    def end_suite(suite)
      puts; puts
      puts timestamp
      puts

      ## if verbose
      unless record[:omit].empty?
        puts "OMISSIONS:\n\n"
        puts record[:omit].map{ |u| u.to_s }.sort.join('  ')
        puts
      end
      ## end

      unless record[:pending].empty?
        puts "PENDING:\n\n"
        record[:pending].each do |test_unit, exception|
          puts "    #{test_unit}".ansi(:bold)
          puts "    #{exception}"
          puts "    #{file_and_line(exception)}"
          puts code(exception)
          puts
        end
      end

      unless record[:fail].empty?
        puts "FAILURES:\n\n"
        record[:fail].each do |test_unit, exception|
          puts "    #{test_unit}".ansi(:bold)
          puts "    #{exception}"
          puts "    #{file_and_line(exception)}"
          puts code(exception)
          puts
        end
      end

      unless record[:error].empty?
        puts "ERRORS:\n\n"
        record[:error].each do |test_unit, exception|
          puts "    #{test_unit}".ansi(:bold)
          puts "    #{exception}"
          puts "    #{file_and_line(exception)}"
          puts code(exception)
          puts
        end
      end

      puts tally
    end

  end

end
