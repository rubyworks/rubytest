class RawTest
  def initialize(label, &block)
    @label = label
    @block = block
  end
  def to_s
    @label.to_s
  end
  def call
    @block.call
  end
end

# pass
$TEST_SUITE << RawTest.new("all good")do
end

# fail
$TEST_SUITE << RawTest.new("not so good")do
  e = SyntaxError.new("failure is not an option")
  e.set_assertion(true)
  raise e
end

# error
$TEST_SUITE << RawTest.new("not good at all") do
  raise "example error"
end

# todo
$TEST_SUITE << RawTest.new("it will be done") do
  raise NotImplementedError, "but we're not there yet"
end

# omit
$TEST_SUITE << RawTest.new("forget about it") do
  e = NotImplementedError.new("it just can't be done")
  e.set_assertion(true)
  raise e
end

