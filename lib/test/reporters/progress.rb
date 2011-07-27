require 'test/reporters/abstract'

module Test::Reporters

  # Progess reporter give test counter, precentage and times.
  #
  class Progress < Abstract

    #
    def start_suite(suite)
      @tab   = 0
      @total_count = total_count(suite)
      @start_time  = Time.now
      @test_cache  = {}
      @count       = 0

      max = @total_count.to_s.size

      @layout      = "%#{max}u)  %-14s   %11s  %11s  %4u%%   %s"

      timer_reset
    end

    #
    def start_case(tc)
      tabs tc.to_s.ansi(:bold)
      @tab += 2
    end

    #
    def start_test(test)
       if test.respond_to?(:subtext) && test.subtext
         @test_cache[test.subtext] ||= (
           puts "#{test.subtext}".tabto(@tab)
           true
         )
       end
       timer_reset
    end

    #
    def omit(test)
      show_line("OMIT".ansi(:cyan), test)
    end

    #
    def pass(test)
      show_line("PASS".ansi(:green), test)
    end

    #
    def fail(test, exception)
      show_line("FAIL".ansi(:red), test)
    end

    #
    def error(test, exception)
      show_line("ERROR".ansi(:red), test)
    end

    #
    def todo(test, exception)
      show_line("PENDING".ansi(:yellow), test)
    end

    #
    def finish_test(test)
      #@_last = :test
    end

    #
    def finish_case(tcase)
      #@_last = :test
      @tab -= 2
    end

    #
    def finish_suite(suite)
      puts

      unless record[:omit].empty?
        puts "OMITTED:\n\n"
        puts record[:omit].map{ |u| u.to_s }.sort.join('  ')
        puts
      end

      unless record[:pending].empty?
        puts "PENDING:\n\n"
        record[:pending].reverse_each do |test, exception|
          puts "#{test}".tabto(4)
          puts "#{file_and_line(exception)}".tabto(4)
          puts
        end
      end

      unless record[:fail].empty?
        puts "FAILURES:\n\n"
        record[:fail].reverse_each do |test, exception|
          puts "#{test}".ansi(:bold).tabto(4)
          puts "#{exception}".ansi(:red).tabto(4)
          puts "#{file_and_line(exception)}".tabto(4)
          puts code_snippet(exception).tabto(4)
          #puts "    #{exception.backtrace[0]}"
          puts
        end
      end

      unless record[:error].empty?
        puts "ERRORS:\n\n"
        record[:error].reverse_each do |test, exception|
          trace = clean_backtrace(exception)[1..-1]

          puts "#{test}".ansi(:bold).tabto(4)
          puts "#{exception.class}".ansi(:red).tabto(4)
          puts "#{exception}".ansi(:red).tabto(4)
          puts "#{file_and_line(exception)}".tabto(4)
          puts code_snippet(exception).tabto(4)
          puts trace.join("\n").tabto(4) unless trace.empty?
          puts
        end
      end

      puts
      puts timestamp
      puts
      puts tally
    end

    #
    def show_line(status, test)
      @count += 1
      data = [@count, status, timer, clock, counter, test.to_s.ansi(:bold)]
      puts (" " * @tab) + (@layout % data)
    end

    #
    def counter
      ((@count.to_f / @total_count) * 100).round.to_s
    end

    #
    def clock
      secs = Time.now - @start_time
      return "%0.5fs" % [secs.to_s]
    end

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

    #
    def tabs(str=nil)
      if str
        puts(str.tabto(@tab))
      else
        puts
      end
    end

  end

end




=begin
      if cover?

        unless uncovered_cases.empty?
          unc = uncovered_cases.map do |mod|
            yellow(mod.name)
          end.join(", ")
          puts "\nUncovered Cases: " + unc
        end

        unless uncovered_units.empty?
          unc = uncovered_units.map do |unit|
            yellow(unit)
          end.join(", ")
          puts "\nUncovered Units: " + unc
        end

        #unless uncovered.empty?
        #  unc = uncovered.map do |unit|
        #    yellow(unit)
        #  end.join(", ")
        #  puts "\nUncovered: " + unc
        #end

        unless undefined_units.empty?
          unc = undefined_units.map do |unit|
            yellow(unit)
          end.join(", ")
          puts "\nUndefined Units: " + unc
        end

      end
=end

