module Test

  #
  def self.run(name=:default, &block)
    @config ||= {}
    @config[name.to_s] = block
  end

  def self.config
    @config ||= {}
  end

  #
  class Config

    # Test configuration file.
    #
    # The name of the file is an ode to the original Ruby cli test tool.
    #
    # @example
    #   .test
    #   .testrb
    #   .test.rb
    #   .config/test.rb
    #
    GLOB_RC = '{.testrb,.test.rb,.test,.config/test.rb,config/test.rb}'

    #
    GLOB_ROOT = '{.ruby,.git,.hg}'

    def self.load
      super(rc_file) if rc_file
    end

    # Find rc file.
    def self.rc_file
      @rc_file ||= (
        glob    = GLOB_RC
        stop    = root
        default = nil
        dir     = Dir.pwd
        until dir == stop
          file = Dir[File.join(dir, glob)].first
          break file if file
          dir = File.dirname(dir)
        end
        file ? file : default
      )
    end

    # Find project root.
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

  end

end
