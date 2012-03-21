module Test

  #
  def self.run(name=nil, &block)
    name = name ? name : 'default'

    @config ||= {}
    @config[name.to_s] = block
  end

  #
  def self.config
    @config ||= {}
  end

  # Handle test run configruation.
  #
  # @todo Why not use the instace level for `Test.config` ?
  #
  class Config

    # Tradional test configuration file glob. This glob
    # looks for a `Testfile` or a `.test` file.
    # Either can have an optional `.rb` extension.
    GLOB_RC = '{testfile.rb,testfile,.test.rb,.test}'

    # If a root level test file can't be found, then use this
    # glob to search the task directory for `*.rubytest` files.
    GLOB_TASK = 'task/*.rubytest'

    # Glob used to find project root directory.
    GLOB_ROOT = '{.ruby,.git,.hg,_darcs,lib/}'

    #
    # Load configuration. This will first look for a root level `Testfile.rb`
    # or `.test.rb` file. Failing that it will look for `task/*.rubytest` files.
    # An example entry into any of these look like:
    #
    #   Test.run :name do |run|
    #     run.files << 'test/case_*.rb'
    #   end
    #
    # Use `:default` for name for non-specific profile and `:common` for code that
    # should apply to all configurations.
    #
    # Failing any traditional configuration files, the Confection system will
    # be used. An example entry in a projects `Confile` is:
    #
    #   config :test, :name do |run|
    #     run.files << 'test/case_*.rb'
    #   end
    #
    # You can leave the `:name` parameter out for `:default`.
    #
    def self.load
      if rc_files.empty?
        if confection_file
          require 'confection'
          confection('test', '*').each do |c|
            name = c.profile ? c.profile : :default
            Test.run(name, &c)
          end
        end
      else
        rc_files.each do |file|
          super(file)
        end
      end
    end

    #
    def self.confection_file
      @confection_file ||= (
        Dir.glob(File.join(root, '{,.}confile{,.rb}'), File::FNM_CASEFOLD).first
      )
    end

    # Find rc file.
    def self.rc_files
      @rc_files ||= (
        if file = Dir.glob(File.join(root, GLOB_RC), File::FNM_CASEFOLD).first
          [file]
        else
          Dir.glob(File.join(root, GLOB_TASK))
        end
      )

      #  glob    = GLOB_RC
      #  stop    = root
      #  default = nil
      #  dir     = Dir.pwd
      #  file    = nil
      #  loop do
      #    files = Dir.glob(File.join(dir, glob), File::FNM_CASEFOLD)
      #    file = files.find{ |f| File.file?(f) }
      #    break file if file
      #    break if dir == stop
      #    dir = File.dirname(dir)
      #    break if dir == '/'
      #  end
      #  file ? file : default
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

    # Load and cache a project's `.ruby` file.
    #
    # @return [Hash] Project's loaded `.ruby` file, if it has one.
    def self.dotruby
      @dotruby ||= (
        drfile = File.join(root, '.ruby')
        if File.exist?(drfile)
          YAML.load_file(drfile)
        else
          {}
        end
      )
    end

    # Setup $LOAD_PATH based on .ruby file.
    #
    # @todo Maybe we should not fallback to typical load path?
    def self.load_path_setup
      if load_paths = dotruby['load_path']
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

  end

end
