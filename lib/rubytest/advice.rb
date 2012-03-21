module Test

  # The Advice class is an observer that can be customized to 
  # initiate before, after and upon procedures for all of RubyTests
  # observable points.
  #
  # Only one procedure is allowed per-point.
  #
  class Advice

    #
    def self.joinpoints
      @joinpoints ||= []
    end

    #
    def self.joinpoint(name)
      joinpoints << name.to_sym

      class_eval %{
        def #{name}(*args)
          @table[:#{name}].call(*args) if @table.key?(:#{name})
        end
      }
    end

    #
    def initialize
      @table = {}
    end

    #
    joinpoint :before_suite

    #
    joinpoint :before_case

    #
    joinpoint :skip_test

    #
    joinpoint :before_test

    #
    joinpoint :pass

    #
    joinpoint :fail

    #
    joinpoint :error

    #
    joinpoint :todo

    #
    joinpoint :after_test

    #
    joinpoint :after_case

    #
    joinpoint :after_suite

    #
    #def [](key)
    #  @table[key.to_sym]
    #end

    # Add a procedure to one of the join-points.
    def join(type, &block)
      type = valid_type(type) 
      @table[type] = block
    end

    # Ignore any other signals (precautionary).
    def method_missing(*)
    end

  private

    #def invoke(symbol, *args)
    #  if @table.key?(symbol)
    #    self[symbol].call(*args)
    #  end
    #end

    def valid_type(type)
      type = type.to_sym
      unless self.class.joinpoints.include?(type)
        raise ArgumentError, "not a valid advice type -- #{type}"
      end
      type
    end

  end

end
