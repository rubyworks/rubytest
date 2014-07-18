require 'rubytest'

at_exit {
  success = Test.run!(ENV['profile'] || ENV['p'])
  exit -1 unless success
}

