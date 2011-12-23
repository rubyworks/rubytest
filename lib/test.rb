# TODO: Do we really even need this `test.rb` file?

if RUBY_VERSION < '1.9'
  require 'test/autorun'
else
  require_relative 'test/autorun'
end
