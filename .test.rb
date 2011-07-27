Test.run(:common) do |run|
  run.files << 'test/*_case.rb'
end

Test.run(:cov) do |run|
  SimpleCov.start do |cov|
    cov.coverage_dir = 'log/coverage'
  end
end

