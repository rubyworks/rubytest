module Test

  # Recorder class is an observer that tracks all tests
  # that are run and categorizes them according to their
  # test status.
  class Recorder

    def initialize
      @table = Hash.new{ |h,k| h[k] = [] }
    end

    def [](key)
      @table[key.to_sym]
    end

    #
    def skip_test(test, reason)
      self[:skip] << [test, reason]
    end

    def skip_case(test_case, reason)
      self[:skip] << [test_case, reason]
    end

    # Add `test` to pass set.
    def pass(test)
      self[:pass] << test
    end

    def fail(test, exception)
      self[:fail] << [test, exception]
    end

    def error(test, exception)
      self[:error] << [test, exception]
    end

    def todo(test, exception)
      self[:todo] << [test, exception]
    end

    #def omit(test, exception)
    #  self[:omit] << [test, exception]
    #end

    # Returns true if tests were recorded without errors or failures.
    def success?
      return false unless self[:error].empty? && self[:fail].empty?

      [:pass, :todo, :skip].any?{ |status| !self[status].empty? }
    end

    # Ignore any other signals.
    def method_missing(*a)
    end

  end

end
