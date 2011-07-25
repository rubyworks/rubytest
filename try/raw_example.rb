test = Object.new
def test.call
  raise "example error"
end

$TEST_SUITE << test

