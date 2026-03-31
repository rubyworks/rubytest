# Ruby Test - Universal Ruby Test Harness

$TEST_SUITE          = [] unless defined?($TEST_SUITE)
$RUBY_IGNORE_CALLERS = [] unless defined?($RUBY_IGNORE_CALLERS)

require 'ansi/core'

module Test
  VERSION = '0.9.0'
end

require_relative 'rubytest/core_ext'
require_relative 'rubytest/code_snippet'
require_relative 'rubytest/config'
require_relative 'rubytest/recorder'
require_relative 'rubytest/advice'
require_relative 'rubytest/runner'
require_relative 'rubytest/format/abstract'
require_relative 'rubytest/format/abstract_hash'
