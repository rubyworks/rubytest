module Test

  # Configure test run via a block then will be passed a `Config` instance.
  #
  # @return [Proc]
  def self.configure(&block)
    configuration.apply(&block)
  end

  # Passive store for configuration settings. Settings aren't applied until
  # just before tests are run.
  #
  # @return [Proc]
  def self.configuration
    @config ||= Config.new
  end

  ##
  # Encapsulates test run configruation.
  #
  class Config

    # Default report is in the old "dot-progress" format.
    DEFAULT_FORMAT = 'dotprogress'

    # Glob used to find project root directory.
    GLOB_ROOT = '{.index,.gemspec,.git,.hg,_darcs,lib/}'

    # RubyTest configuration file can be in `.test`, '.test.rb`, `etc/test.rb`
    # or `config/test.rb`.
    #
    # @deprecated Use manual -c/--config option instead.
    GLOB_CONFIG = '{.test,.test.rb,etc/test.rb,config/test.rb}'

    #
    def self.assertionless
      @assertionless
    end

    #
    def self.assertionless=(boolean)
      @assertionaless = !!boolean
    end

    # Load configuration file. An example file might look like:
    #
    #   Test.configure do |run|
    #     run.files << 'test/case_*.rb'
    #   end
    #
    # @deprecated Planned for deprecation in April 2013.
    def self.load_config
      if config_file
        file = config_file.sub(Dir.pwd+'/','')
        $stderr.puts "Automatic #{file} loading has been deprecated. Use -c option for future version."
        load config_file
      end
    end

    # Find traditional configuration file.
    #
    # @deprecated
    def self.config_file
      @config_file ||= Dir.glob(File.join(root, GLOB_CONFIG)).first
    end

    # Find and cache project root directory.
    #
    # @return [String] Project's root path.
    def self.root
      @root ||= (
        glob    = GLOB_ROOT
        stop    = '/'
        default = Dir.pwd
        dir     = Dir.pwd
        until dir == stop
          break dir if Dir[File.join(dir, glob)].first
          dir = File.dirname(dir)
        end
        dir == stop ? default : dir
      )
    end

    # Load and cache a project's `.index` file, if it has one.
    #
    # @return [Hash] YAML loaded `.index` file, or empty hash.
    def self.dotindex
      @dotindex ||= (
        file = File.join(root, '.index')
        if File.exist?(file)
          require 'yaml'
          YAML.load_file(file) rescue {}
        else
          {}
        end
      )
    end

    # TODO: Should config files be required relative to project root
    #       or relatvie to current working directory?

    # TODO: Use load instead of require?

    # Require a configuration file. Configuration files are required
    # relative to the project's root directory.
    #
    # @return nothing.
    def self.require_config(file)
      #if File.exist?(file)
      #  require file
      #else
        glob = File.join(root, "#{file}{,.rb}")
        if file = Dir.glob(glob).first
          require file
        end
      #end
    end

    # Setup $LOAD_PATH based on project's `.index` file, if an
    # index file is not found, then default to `lib/` if it exists.
    #
    def self.load_path_setup
      if load_paths = (dotindex['paths'] || {})['lib']
        load_paths.each do |path|
          $LOAD_PATH.unshift(File.join(root, path))
        end
      else
        typical_load_path = File.join(root, 'lib')
        if File.directory?(typical_load_path)
          $LOAD_PATH.unshift(typical_load_path) 
        end
      end
    end

    # Initialize new Config instance.
    def initialize(&block)
      @files    = env(:testfiles, [])
      @match    = env(:match, [])
      @tags     = env(:tags,  [])
      @units    = env(:units, [])
      @format   = env(:format, DEFAULT_FORMAT)
      @requires = env(:requires, [])
      @loadpath = env(:loadpath, [])

      self.class.load_config

      apply(&block)
    end

    # Evaluate configuration block.
    #
    # @return nothing
    def apply(&block)
      block.call(self) if block
    end

    # Default test suite ($TEST_SUITE).
    #
    # @return [Array]
    def suite
      $TEST_SUITE
    end

    # Default list of test files to load.
    #
    # @return [Array<String>]
    def files
      @files
    end
    alias test_files files

    # Set the list of test files to run. Entries can be file glob patterns.
    # This can also be set via the `RUBYTEST_FILES` environment variable.
    #
    # @return [Array<String>]
    def files=(list)
      @files = pathlist(list)
    end
    alias test_files= files=

    # Paths to add to $LOAD_PATH.
    #
    # @return [Array<String>]
    attr :loadpath

    # Set paths to add to $LOAD_PATH. This can also be set via the
    # `RUBYTEST_LOADPATH` environment variable.
    #
    # @return [Array<String>]
    def loadpath=(list)
      @loadpath = pathlist(list)
    end

    # Scripts to require prior to tests.
    #
    # @return [Array<String>]
    attr :requires

    # Set the features that need to be required before the
    # test files. This can also be set via the `RUBYTEST_REQUIRES`
    # environment variable.
    #
    # @return [Array<String>]
    def requires=(list)
      @requires = pathlist(list)
    end

    # Name of test report format, by default it is `dotprogress`.
    #
    # @return [String] format
    def format
      @format
    end

    # Set test report format. The format can also be set via the
    #  `RUBYTEST_FORMAT` environment variable.
    #
    # @return [String] format
    def format=(format)
      @format = format
    end

    # Provide extra details in reports?
    #
    # @return [Boolean]
    def verbose?
      @verbose
    end

    # Set verbose mode. The verbosity can also be set via the
    #  `RUBYTEST_VERBOSE` environment variable.
    #
    # @return [Boolean]
    def verbose=(boolean)
      @verbose = !!boolean
    end

    # Description match for filtering tests.
    #
    # @return [Array<String>]
    def match
      @match
    end

    # Set the description matches for filtering tests. The list of matches
    # can also be set via the `RUBYTEST_MATCH` environment variable.
    # Separate them like paths, with `:` or `;` marks.
    #
    # @return [Array<String>]
    def match=(list)
      @match = pathlist(list)
    end

    # Selection of tags for filtering tests. The list of tags can also
    # be set via the `RUBYTEST_TAGS` environment variable. Separate
    # each tag with `:` or `;` marks.
    #
    # @return [Array<String>]
    def tags
      @tags
    end

    # Set the list of tags for filtering tests. The list of tags can also
    # be set via the `RUBYTEST_TAGS` environment variable. Separate
    # each tag with `:` or `;` marks.
    #
    # @return [Array<String>]
    def tags=(list)
      @tags = pathlist(list)
    end

    # List of units with which to filter tests. It is an array of strings
    # which are matched against module, class and method names.
    #
    # @return [Array<String>]
    def units
      @units
    end

    # Set the list of units with which to filter tests. It is an array of 
    # strings which are matched against module, class and method names.
    #
    # @return [Array<String>]
    def units=(list)
      @units = pathlist(list)
    end

    # Hard is a synonym for assertionless.
    #
    # @return [Boolean]
    def hard?
      @hard || self.class.assertionless
    end

    # Hard is a synonym for assertionless.
    #
    # @return [Boolean]
    def hard=(boolean)
      @hard = !!boolean
    end

    # Automatically modify the `$LOAD_PATH`?
    #
    # @return [Boolean]
    def autopath?
      @autopath
    end

    # Automatically modify the `$LOAD_PATH`?
    #
    # @return [Boolean]
    def autopath=(boolean)
      @autopath = !!boolean
    end

    #
    #attr :chroot

    #def chroot=(boolean)
    #  @chroot = !!boolean
    #end

    #
    #attr :chdir

    #def chdir=(dir)
    #  @chroot = dir.to_s
    #end

    # The mode is only useful for specialied purposes, such how
    # to run tests via the Rake task. It has no general purpose
    # use and can be ignored in most cases.
    #
    # @return [Symbol]
    def mode
      @mode
    end

    # The mode is only useful for specialied purposes, such how
    # to run tests via the Rake task. It has no general purpose
    # use and can be ignored in most cases.
    #
    # @return [String]
    def mode=(type)
      @mode = type.to_s
    end

    # Convert configuration to shell options, compatible with the
    # rubytest command line.
    #
    # @return [Array<String>]
    def to_shellwords
      argv = []
      argv << %[--autoload] if autoload?
      argv << %[--verbose]  if verbose?
      argv << %[--format="#{format}"] if format
      argv << %[--match="#{match.join(';')}"] unless match.empty?
      argv << %[--units="#{units.join(';')}"] unless units.empty?
      argv << %[--tags="#{tags.join(';')}"]   unless tags.empty?
      argv << %[--loadpath="#{loadpath.join(';')}"] unless loadpath.empty?
      argv << %[--requires="#{requires.join(';')}"] unless requires.empty?
      argv << files.join(' ') unless files.empty?
      argv
    end

  private

    # Lookup environment variable with name `RUBYTEST_{NAME}`,
    # and transform in according to the type of the given
    # default. If the environment variable is not set then
    # returns the default.
    #
    # @return [Object]
    def env(name, default=nil)
      value = ENV["RUBYTEST_#{name.capitalize}"]

      case default
      when Array
        return value.split(/[:;]/) if value 
      else
        return value if value
      end
      default
    end

    # If given a String then split up at `:` and `;` markers.
    # Otherwise ensure the list is an Array and the entries are
    # all strings and not empty.
    #
    # @return [Array<String>]
    def pathlist(list)
      case list
      when String
        list = list.split(/[:;]/)
      else
        list = Array(list).map{ |path| path.to_s }
      end
      list.reject{ |path| path.strip.empty? }
    end

  end

end
