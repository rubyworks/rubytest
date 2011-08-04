$TEST_SUITE = [] unless defined?($TEST_SUITE)

at_exit {
  if RUBY_VERSION < '1.9'
    require 'test/runner'
  else
    require_relative 'runner'
  end

  suite   = $TEST_SUITE
  options = {
    :format => ENV['ruby-test-format']  # TODO: better name?
  }

  runner  = Test::Runner.new(suite, options)
  success = runner.run
  exit -1 unless success
}
