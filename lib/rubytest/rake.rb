require 'rubytest'
require 'rake'
require 'rake/tasklib'

module Test

  ##
  # Rake subspace.
  #
  module Rake

    ##
    # Define a rake task that runs tests.
    #
    #   require 'rubytest/rake'
    #
    #   Test::Rake::TestTask.new do |run|
    #     run.loadpath 'lib'
    #     run.files << 'test/*_test.rb'
    #   end
    #
    # The block is given the task's Test::Config, the same object that
    # `Test.configure` yields. Without any files, the task runs whichever
    # of DEFAULT_TESTS match, and without a load path it adds `lib`.
    #
    # The `TEST` environment variable selects the tests to run for one
    # invocation, in place of the task's own: `rake test TEST=test/foo_test.rb`.
    # Separate several files or globs with `:` or `;`.
    #
    # Where the platform can fork, tests run in a child process, so that
    # what they load doesn't stay in Rake's. If the run is unsuccessful the
    # task exits with status 1.
    #
    class TestTask < ::Rake::TaskLib

      # Globs used to find test files when the task is given none.
      DEFAULT_TESTS = [
        'test/**/case_*.rb',
        'test/**/*_case.rb',
        'test/**/test_*.rb',
        'test/**/*_test.rb'
      ]

      # Name of the task.
      #
      # @return [String]
      attr :name

      # Test run configuration.
      #
      # @return [Config]
      attr :config

      # Initialize new Rake::TestTask instance.
      #
      def initialize(name='test', desc='run tests', &block)
        @name = (name || 'test').to_s
        @desc = desc

        @config = Test::Config.new

        block.call(@config) if block

        define_task
      end

      # Define rake task for testing.
      #
      # @return nothing
      def define_task
        desc @desc
        task @name do
          run
        end
      end

      # Run tests, in a child process if possible, otherwise in this one.
      # Exits with status 1 if the run is unsuccessful.
      #
      # @return nothing
      def run
        prepare
        success = Process.respond_to?(:fork) ? run_in_fork : run_here
        exit 1 unless success
      end

    private

      # Settle the files and load path the run will use.
      def prepare
        if ENV['TEST']
          config.files = ENV['TEST'].split(/[:;]/)
        elsif config.files.empty?
          config.files = default_tests
        end
        config.loadpath << 'lib' if config.loadpath.empty?
      end

      # The default globs that match at least one file. The runner fails a
      # glob that matches nothing, so the others are left out.
      #
      # @return [Array<String>]
      def default_tests
        base  = config.chdir || Dir.pwd
        globs = DEFAULT_TESTS.reject{ |glob| Dir.glob(glob, base: base).empty? }
        if globs.empty?
          raise ArgumentError, "no test files found; looked for #{DEFAULT_TESTS.join(', ')}"
        end
        globs
      end

      # @return [Boolean] Whether the run was successful.
      def run_here
        Test::Runner.new(config).run
      end

      # @return [Boolean] Whether the run was successful.
      def run_in_fork
        pid = fork { exit(run_here ? 0 : 1) }
        Process.wait(pid)
        $?.success?
      end

    end

  end

end
