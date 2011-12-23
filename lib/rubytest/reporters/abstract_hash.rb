# encoding: UTF-8

module Test::Reporters

  # Hash Abstract is a base class for the TAP-Y
  # and TAP-J reporters.
  #
  class AbstractHash < Abstract

    #
    def begin_suite(suite)
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
    def begin_case(test_case)
      h = {}
      h['type' ] = 'case'
      h['level'] = @case_level

      merge_subtype h, test_case
      merge_setup   h, test_case
      merge_label   h, test_case

      @case_level += 1

      return h
    end

    #
    def begin_test(test)
      @test_index += 1
    end

    #
    def pass(test) #, backtrace=nil)
      h = {}
      h['type'  ] = 'test'
      h['status'] = 'pass'

      merge_subtype      h, test
      merge_setup        h, test
      merge_label        h, test
      #merge_comparison  h, test, exception
      #merge_coverage    h, test
      merge_source       h, test
      merge_time         h

      return h
    end

    #
    def fail(test, exception)
      h = {}
      h['type'  ] = 'test'
      h['status'] = 'fail'

      merge_subtype      h, test
      merge_setup        h, test
      merge_label        h, test
      #merge_comparison  h, test, exception
      #merge_coverage    h, test
      merge_source       h, test
      merge_exception    h, test, exception
      merge_time         h
 
      return h
    end

    #
    def error(test, exception)
      h = {}
      h['type'  ] = 'test'
      h['status'] = 'error'

      merge_subtype      h, test
      merge_setup        h, test
      merge_label        h, test
      #merge_comparison  h, test, exception
      #merge_coverage    h, test
      merge_source       h, test
      merge_exception    h, test, exception, true
      merge_time         h

      return h
    end

    #
    def todo(test, exception)
      h = {}
      h['type'  ] = 'test'
      h['status'] = 'todo'

      merge_subtype      h, test
      merge_setup        h, test
      merge_label        h, test
      #merge_comparison  h, test, exception
      #merge_coverage    h, test
      merge_source       h, test
      merge_exception    h, test, exception
      merge_time         h

      return h
    end

    #
    def omit(test, exception)
      h = {}
      h['type'  ] = 'test'
      h['status'] = 'omit'

      merge_subtype      h, test
      merge_setup        h, test
      merge_label        h, test
      #merge_comparison  h, test, exception
      #merge_coverage    h, test
      merge_source       h, test
      merge_exception    h, test, exception
      merge_time         h

      return h
    end

    #
    def end_case(test_case)
      @case_level -= 1
    end

    #
    def end_suite(suite)
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

    # TODO: topic or setup ?
    def merge_setup(hash, test)
      #hash['setup'] = test.setup.to_s if test.respond_to?(:setup)
      hash['setup'] = test.topic.to_s if test.respond_to?(:topic)
    end

    # Add test description to hash.
    def merge_label(hash, test)
      hash['label'] = test.to_s.strip
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
