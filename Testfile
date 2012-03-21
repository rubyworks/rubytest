Test.run(:default) do |run|
  run.files << 'test/*_case.rb'
end

Test.run(:cov) do |run|
  run.files << 'test/*_case.rb'
  SimpleCov.start do |cov|
    cov.coverage_dir = 'log/coverage'
  end
end

