require 'rubytest'

at_exit {
  success = Test.run
  exit -1 unless success
}

