module Test

  # Configure test run via a block then will be passed a `Config` instance.
  #
  # @return [Config]
  def self.configure(&block)
    if reconfigure?
      configuration.apply(&block)
    else
      @config = Config.new(&block)
    end
  end

  # Reconfigure test run via a block then will be passed the {Config} instance.
  # Unlike `configure` this does not create a new Config instance, but instead
  # augments the current configuration.
  #
  # @return [Config]
  def self.reconfigure?
    @reconfigure
  end

  # Get the current configuration.
  #
  # @return [Config]
  def self.configuration(reconfigurable=false)
    @reconfigure = true if reconfigurable
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

    # RubyTest configuration file can be in '.test.rb`, `etc/test.rb`
    # or `config/test.rb`, `.test`, in that order of precedence.
    #
    # @deprecated Use manual -c/--config option instead.
    GLOB_CONFIG = '{.test.rb,etc/test.rb,config/test.rb,.test}'

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
        $stderr.puts "Automatic #{file} loading has been deprecated.\nUse -c option for future version."
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
    def initialize(settings={}, &block)
      @format   = nil
      @autopath = nil
      @chdir    = nil
      @files    = []
      @tags     = []
      @match    = []
      @units    = []
      @requires = []
      @loadpath = []

      #apply_environment

      settings.each do |k,v|
        send("#{k}=", v)
      end

      self.class.load_config # deprecated!!!

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
      @suite ||= $TEST_SUITE
    end

    # This is not really for general, but it is useful for Ruby Test's
    # own tests, to isolate tests.
    def suite=(test_objects)
      @suite = Array(test_objects)
    end

    # List of test files to run.
    #
    # @return [Array<String>]
    def files
      @files
    end
    alias test_files files

    # Set the list of test files to run. Entries can be file glob patterns.
    #
    # @return [Array<String>]
    def files=(list)
      @files = makelist(list)
    end
    alias test_files= files=

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
      @autopath = !! boolean
    end

    # Paths to add to $LOAD_PATH.
    #
    # @return [Array<String>]
    attr :loadpath

    # Set paths to add to $LOAD_PATH.
    #
    # @return [Array<String>]
    def loadpath=(list)
      @loadpath = makelist(list)
    end

    # Scripts to require prior to tests.
    #
    # @return [Array<String>]
    attr :requires

    # Set the features that need to be required before the
    # test files.
    #
    # @return [Array<String>]
    def requires=(list)
      @requires = makelist(list)
    end

    # Name of test report format, by default it is `dotprogress`.
    #
    # @return [String] format
    def format
      @format || DEFAULT_FORMAT
    end

    # Set test report format.
    #
    # @return [String] format
    def format=(format)
      @format = format.to_s
    end

    # Provide extra details in reports?
    #
    # @return [Boolean]
    def verbose?
      @verbose
    end

    # Set verbose mode.
    #
    # @return [Boolean]
    def verbose=(boolean)
      @verbose = !! boolean
    end

    # Selection of tags for filtering tests.
    #
    # @return [Array<String>]
    def tags
      @tags
    end

    # Set the list of tags for filtering tests.
    #
    # @return [Array<String>]
    def tags=(list)
      @tags = makelist(list)
    end

    # Description match for filtering tests.
    #
    # @return [Array<String>]
    def match
      @match
    end

    # Set the description matches for filtering tests.
    #
    # @return [Array<String>]
    def match=(list)
      @match = makelist(list)
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
      @units = makelist(list)
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
      @hard = !! boolean
    end

    # Change to this directory before running tests.
    #
    # @return [String]
    def chdir
      @chdir
    end

    # Set directory to change to before running tests.
    #
    # @return [String]
    def chdir=(dir)
      @chdir = dir.to_s
    end

    # The mode is only useful for specialied purposes, such as how
    # to run tests via the Rake task. It has no general purpose
    # and can be ignored in most cases.
    #
    # @return [String]
    def mode
      @mode
    end

    # The mode is only useful for specialied purposes, such as how
    # to run tests via the Rake task. It has no general purpose
    # and can be ignored in most cases.
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
      argv << %[--autopath] if autopath?
      argv << %[--verbose]  if verbose?
      argv << %[--format="#{format}"] if format
      argv << %[--chdir="#{chdir}"] if chdir
      argv << %[--tags="#{tags.join(';')}"]   unless tags.empty?
      argv << %[--match="#{match.join(';')}"] unless match.empty?
      argv << %[--units="#{units.join(';')}"] unless units.empty?
      argv << %[--loadpath="#{loadpath.join(';')}"] unless loadpath.empty?
      argv << %[--requires="#{requires.join(';')}"] unless requires.empty?
      argv << files.join(' ') unless files.empty?
      argv
    end

    # Apply environment, overriding any previous configuration settings.
    #
    # @todo Better name for this method?
    # @return nothing
    def apply_environment_overrides
      @format   = env(:format,   @format)
      @autopath = env(:autopath, @autopath)
      @files    = env(:files,    @files)
      @match    = env(:match,    @match)
      @tags     = env(:tags,     @tags)
      @units    = env(:units,    @units)
      @requires = env(:requires, @requires)
      @loadpath = env(:loadpath, @loadpath)
    end

    # Apply environment as underlying defaults for unset configuration
    # settings.
    #
    # @return nothing
    def apply_environment_defaults
      @format   = env(:format,   @format)   if @format.nil?
      @autopath = env(:autopath, @autopath) if @autopath.nil?
      @files    = env(:files,    @files)    if @files.empty?
      @match    = env(:match,    @match)    if @match.empty?
      @tags     = env(:tags,     @tags)     if @tags.empty?
      @units    = env(:units,    @units)    if @units.empty?
      @requires = env(:requires, @requires) if @requires.empty?
      @loadpath = env(:loadpath, @loadpath) if @loadpath.empty?
    end

    # Load configuration file.
    #
    # @return [Boolean] true if file was required
    def load_config(file)
      try_paths = ['etc', 'config']
      try_paths.concat loadpath
      try_paths << '.'
      try_paths = try_paths.uniq

      if chdir
        try_paths = try_paths.map{ |path| File.join(chdir, path) }
      end

      hold_path = $LOAD_PATH.dup
      $LOAD_PATH.replace(try_paths)
      begin
        success = require file
      ensure
        $LOAD_PATH.replace(hold_path)
      end
      success
    end

  private

    # Lookup environment variable with name `rubytest_{name}`,
    # and transform in according to the type of the given
    # default. If the environment variable is not set then
    # returns the default.
    #
    # @return [Object]
    def env(name, default=nil)
      value = ENV["rubytest_#{name}".downcase]

      case default
      when Array
        return makelist(value) if value 
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
    def makelist(list)
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
