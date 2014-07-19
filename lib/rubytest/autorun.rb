require 'rubytest'

at_exit {
  Test.run!(ENV['profile'] || ENV['p'])
  #success = Test.run!(ENV['profile'] || ENV['p'])
  #exit -1 unless success
}

