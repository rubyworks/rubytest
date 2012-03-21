module Test

  #
  def self.run(name=:default, &block)
    @config ||= {}
    @config[name.to_s] = block
  end

  def self.config
    @config ||= {}
  end

  # TODO: Add optional support for Confection.

  #
  class Config

    # Test configuration file.
    #
    # @example
    #   .test
    #   .test.rb
    #   task/test.rb
    #   Testfile
    #
    # @todo Too many options for ruby-test configuration file.
    GLOB_RC = '{,.,task/}test{,file}{.rb,}'

    #
    GLOB_ROOT = '{.ruby,.git,.hg}'

    #
    def self.load
      super(rc_file) if rc_file
      #Ruth.module_eval(File.read(rc_file)) if rc_file
    end

    # Find rc file.
    def self.rc_file
      @rc_file ||= (
        glob    = GLOB_RC
        stop    = root
        default = nil
        dir     = Dir.pwd
        file    = nil
        loop do
          files = Dir.glob(File.join(dir, glob), File::FNM_CASEFOLD)
          file = files.find{ |f| File.file?(f) }
          break file if file
          break if dir == stop
          dir = File.dirname(dir)
          break if dir == '/'
        end
        file ? file : default
      )
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
