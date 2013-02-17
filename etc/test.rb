# This is just here as an example.
Test.configure 'coverage' do |run|
  run.loadpath << 'lib'
  run.test_files << 'test/*_case.rb'

  run.before do
    require 'simplecov'
    Simplecov.command_name File.basename($0)
    SimpleCov.start do
      add_filter 'test/'
      coverage_dir 'log/coverage'
    end
  end
end

