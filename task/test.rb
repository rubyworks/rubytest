Test.run(:default) do |run|
  run.files << 'test/*_case.rb'
end

Test.run(:cov) do |run|
  run.files << 'test/*_case.rb'

  require 'simplecov'
  SimpleCov.start do
    coverage_dir 'log/coverage'
  end
end

