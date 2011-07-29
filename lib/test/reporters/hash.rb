require 'test/reporters/abstract'

module Test::Reporters

  # Hash Abstract is a base class for the TAP-Y
  # and TAP-J reporters.
  #
  class HashAbstract < Abstract

    #
    def start_suite(suite)
      require 'yaml'

      @start_time = Time.now
      @case_level = 0
      @test_index = 0

      now = Time.now.strftime('%Y-%m-%d %H:%M:%S')

      h = {
        'type'  => 'suite',
        'start' => now,
        'count' => total_count(suite)
      }

      return h
    end

    #
    def start_case(test_case)
      h = {}
      h['type' ] = 'case'
      h['level'] = @case_level

      merge_subtype      h, test_case
      merge_setup        h, test_case
      merge_description  h, test_case

      @case_level += 1

      return h
    end

    #
    def start_test(unit)
      @test_index += 1
    end

    #
    def pass(unit) #, backtrace=nil)
      h = {}
      h['type'  ] = 'unit'
      h['status'] = 'pass'

      merge_subtype      h, unit
      merge_setup        h, unit
      merge_description  h, unit
      #merge_comparison  h, unit, exception
      #merge_coverage    h, unit
      merge_source       h, unit
      merge_time         h

      return h
    end

    #
    def fail(unit, exception)
      h = {}
      h['type'  ] = 'unit'
      h['status'] = 'fail'

      merge_subtype      h, unit
      merge_setup        h, unit
      merge_description  h, unit
      #merge_comparison  h, unit, exception
      #merge_coverage    h, unit
      merge_source       h, unit
      merge_exception    h, unit, exception
      merge_time         h
 
      return h
    end

    #
    def error(unit, exception)
      h = {}
      h['type'  ] = 'unit'
      h['status'] = 'error'

      merge_subtype      h, unit
      merge_setup        h, unit
      merge_description  h, unit
      #merge_comparison  h, unit, exception
      #merge_coverage    h, unit
      merge_source       h, unit
      merge_exception    h, unit, exception, true
      merge_time         h

      return h
    end

    #
    def todo(unit, exception)
      h = {}
      h['type'  ] = 'unit'
      h['status'] = 'todo'

      merge_subtype      h, unit
      merge_setup        h, unit
      merge_description  h, unit
      #merge_comparison  h, unit, exception
      #merge_coverage    h, unit
      merge_source       h, unit
      merge_exception    h, unit, exception
      merge_time         h

      return h
    end

    #
    def omit(unit, exception)
      h = {}
      h['type'  ] = 'unit'
      h['status'] = 'omit'

      merge_subtype      h, unit
      merge_setup        h, unit
      merge_description  h, unit
      #merge_comparison  h, unit, exception
      #merge_coverage    h, unit
      merge_source       h, unit
      merge_exception    h, unit, exception
      merge_time         h

      return h
    end

    #
    def finish_case(test_case)
      @case_level -= 1
    end

    #
    def finish_suite(suite)
      h = {
        'type'  => 'tally',
        'time'  => Time.now - @start_time,
        'counts' => {
          'total' => total,
          'pass'  => record[:pass].size,
          'fail'  => record[:fail].size,
          'error' => record[:error].size,
          'omit'  => record[:omit].size,
          'todo'  => record[:todo].size
        }
      }
      return h
    end

  private

    #
    def merge_subtype(hash, test)
      hash['subtype'] = test.type.to_s if test.respond_to?(:type)
    end

    # TODO: setup or subtext ?
    def merge_setup(hash, test)
      hash['setup'] = test.setup.to_s if test.respond_to?(:setup)
    end

    # Add test description to hash.
    def merge_description(hash, test)
      hash['description'] = test.to_s.strip
    end

    # NOTE: Not presently used.
    def merge_comparison(hash, test, exception)
      hash['returned'] = exception.returned
      hash['expected'] = exception.expected
    end

    # Add source location information to hash.
    def merge_source(hash, test)
      if test.respond_to?('source_location')
        file, line = source_location
        hash['file'   ] = file
        hash['line'   ] = line
        hash['source' ] = code(file, line).to_str
        hash['snippet'] = code(file, line).to_omap
      end
    end

    # Add exception subsection of hash.
    def merge_exception(hash, test, exception, bt=false)
      hash['exception'] = {}
      hash['exception']['file'     ] = code(exception).file
      hash['exception']['line'     ] = code(exception).line
      hash['exception']['source'   ] = code(exception).to_str
      hash['exception']['snippet'  ] = code(exception).to_omap
      hash['exception']['message'  ] = exception.message
      hash['exception']['backtrace'] = clean_backtrace(exception) if bt
    end

    # TODO: Really?
    def merge_coverage(hash, test)
      if test.respond_to?(:file_coverage) or test.respond_to?(:code_coverage)
        fc = test.file_coverage
        cc = test.code_coverage
        hash['coverage'] = {}
        hash['coverage']['file'] = fc if fc
        hash['coverage']['code'] = cc if cc
      end
    end

    #
    def merge_time(hash)
      hash['time'] = Time.now - @start_time
    end

  end

end
