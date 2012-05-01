require 'rc'

configure('rubytest') do |config|
  Test.run(config.profile, &config)
end

