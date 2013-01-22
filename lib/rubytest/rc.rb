begin
  require 'rc/api'
  RC.setup 'rubytest' do |config|
    Test.run(config.profile, &config)
  end
rescue LoadError
end

