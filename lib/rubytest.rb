# Ruby Test - Universal Ruby Test Harness

$TEST_SUITE          = [] unless defined?($TEST_SUITE)
$RUBY_IGNORE_CALLERS = [] unless defined?($RUBY_IGNORE_CALLERS)

#require 'brass'  # TODO: Should we require BRASS ?
require 'ansi/core'

module Test
  # Load project index on demand.
  def self.index
    @index ||= (
      require 'yaml'
      __dir__  = File.dirname(__FILE__)
      file = File.expand_path('rubytest.yml', __dir__)
      YAML.load_file(file)
    )
  end

  # Lookup missing constant in project index.
  def self.const_missing(name)
    index[name.to_s.downcase] || super(name)
  end
end

if RUBY_VERSION < '1.9'
  require 'rubytest/core_ext'
  require 'rubytest/code_snippet'
  require 'rubytest/config'
  require 'rubytest/recorder'
  require 'rubytest/advice'
  require 'rubytest/runner'
  require 'rubytest/reporters/abstract'
  require 'rubytest/reporters/abstract_hash'
else
  require_relative 'rubytest/core_ext'
  require_relative 'rubytest/code_snippet'
  require_relative 'rubytest/config'
  require_relative 'rubytest/recorder'
  require_relative 'rubytest/advice'
  require_relative 'rubytest/runner'
  require_relative 'rubytest/reporters/abstract'
  require_relative 'rubytest/reporters/abstract_hash'
end

