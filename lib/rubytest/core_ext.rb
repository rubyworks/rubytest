if RUBY_VERSION < '1.9'
  require 'ruth/core_ext/assertion'
  require 'ruth/core_ext/exception'
  require 'ruth/core_ext/string'
else
  require_relative 'core_ext/assertion'
  require_relative 'core_ext/exception'
  require_relative 'core_ext/string'
end
