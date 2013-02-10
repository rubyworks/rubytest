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

    # Load and cache a project's `.index` file.
    #
    # @return [Hash] Project's loaded `.index` file, if it has one.
    def self.dotindex
      @dotindex ||= (
        file = File.join(root, '.index')
        if File.exist?(file)
          YAML.load_file(file) rescue {}
        else
          {}
        end
      )
    end

    # Require a configuration file.
    #
    # TODO: Should config files be require relative to project root
    #       or relatvie to current working directory?
    #
    # TODO: Use load instead of require?
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
      self.class.load_config
      apply(&block)
    end

    # Evaluate configuration block.
    def apply(&block)
      block.call(self) if block
    end

    # Default test suite ($TEST_SUITE).
    def suite
      $TEST_SUITE
    end

    # Default list of test files to load.
    def files
      @files ||= []
    end

    # Format by default is `dotprogress`. The format can also be set
    # via the `RUBYTEST_FORMAT` environment variable.
    #
    # @return [String] format
    def format
      @format || ENV['RUBYTEST_FORMAT'] || DEFAULT_FORMAT
    end

    # Set test report format.
    def format=(format)
      @format = format
    end

    # Provide extra details in reports?
    def verbose
      @verbose
    end

    # Set verbose mode.
    def verbose=(boolean)
      @verbose = !!boolean
    end

    # Default description match for filtering tests.
    def match
      @match ||= []
    end

    # Default selection of tags for filtering tests.
    def tags
      @tags ||= []
    end

    # Default selection of units for filtering tests.
    def units
      @unit ||= []
    end

    # Hard is a synonym for assertionless.
    def hard
      @hard || self.class.assertionless
    end

    # Hard is a synonym for assertionless.
    def hard=(boolean)
      @hard = !!boolean
    end

    # Automatically modify the `$LOAD_PATH`?
    def autopath
      @autopath
    end

    # Automatically modify the `$LOAD_PATH`?
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

  end

end
