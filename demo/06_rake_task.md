## Rake task

`rubytest/rake` provides a task for running tests from a Rakefile.

    require 'rubytest/rake'
    require 'tmpdir'

    project = Dir.mktmpdir('rubytest-rake')
    Dir.mkdir(File.join(project, 'test'))

    probe = lambda do |label, body|
      <<-RUBY
        probe = Object.new
        probe.define_singleton_method(:call) { #{body} }
        probe.define_singleton_method(:to_s) { #{label.inspect} }
        $TEST_SUITE << probe
      RUBY
    end

    File.write(File.join(project, 'test', 'good_test.rb'), probe.call('good', 'true'))
    File.write(File.join(project, 'bad.rb'), probe.call('bad', "raise Assertion, 'wrong value'"))

    status_of = lambda do |task|
      Dir.chdir(project) do
        begin
          task.run
          0
        rescue SystemExit => exit
          exit.status
        end
      end
    end

The block configures the run, as with `Test.configure`. The task is an
ordinary Rake task.

    passing = Test::Rake::TestTask.new('demo:pass') do |run|
      run.files << 'test/good_test.rb'
      run.format = 'test'
    end

    Rake::Task.task_defined?('demo:pass').assert == true
    status_of.call(passing).assert == 0

A run that fails makes the task exit with status 1, so that `rake` fails too.

    failing = Test::Rake::TestTask.new('demo:fail') do |run|
      run.files << 'bad.rb'
      run.format = 'test'
    end

    status_of.call(failing).assert == 1

Given no files, the task looks under `test/` for files named `test_*.rb`,
`*_test.rb`, `case_*.rb` or `*_case.rb`, and runs whichever of those it
finds. It also puts `lib` on the load path.

    defaults = Test::Rake::TestTask.new('demo:defaults') { |run| run.format = 'test' }

    status_of.call(defaults).assert == 0
    defaults.config.files.assert == ['test/**/*_test.rb']
    defaults.config.loadpath.assert == ['lib']

If it finds none, it says so.

    empty = Dir.mktmpdir('rubytest-rake-empty')
    nothing = Test::Rake::TestTask.new('demo:nothing') { |run| run.format = 'test' }
    missing = begin
      Dir.chdir(empty) { nothing.run }
      nil
    rescue ArgumentError => error
      error
    end

    missing.message.assert.start_with?('no test files found')

The `TEST` environment variable selects the tests for one invocation, in
place of the task's own.

    previous = ENV['TEST']
    begin
      ENV['TEST'] = 'bad.rb'
      status_of.call(passing).assert == 1
      passing.config.files.assert == ['bad.rb']
    ensure
      ENV['TEST'] = previous
    end
