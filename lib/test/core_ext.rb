if RUBY_VERSION < '1.9'
  require 'test/core_ext/assertion'
  require 'test/core_ext/exception'
  require 'test/core_ext/string'
else
  require_relative 'core_ext/assertion'
  require_relative 'core_ext/exception'
  require_relative 'core_ext/string'
end
