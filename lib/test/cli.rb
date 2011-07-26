module Test

  require 'test/runner'

  # Command line interface.
  class Runner

    # Test configuration file. The name of the file is an ode
    # to the original Ruby cli test tool.
    #
    # @example
    #   .testrb
    #   .config/test.rb
    #
    RC_GLOB = '{.testrb,.test.rb,.config/test.rb,config/test.rb}'

    # Test runner command line interface.
    #
    def self.cli(*argv)
      begin
        files, options = cli_options(argv)

        cli_loadrc(files, options)

        suite   = $TEST_SUITE || []
        runner  = new(suite, options)
        success = runner.run

        exit -1 unless success
      rescue => error
        raise error if $DEBUG
        $stderr.puts('ERROR: ' + error.to_s)
      end
    end

    #
    def self.cli_options(argv)
      require 'optparse'
      options = { :loadpath=>[], :requires=>[], :namespace=>[], :tags=>[], :casematch=>[] }
      OptionParser.new do |opt|
        opt.banner = "Usage: ruby-test [options] [files ...]"
        opt.on '-f', '--format NAME', 'report format' do |name|
          options[:format] = name
        end
        #opt.on '-t', '--tag TAG', 'select tests by tag' do |tag|
        #  options[:tags] << tag
        #end
        #opt.on '-n', '--namespace NAME', 'select tests by target component' do |namespace|
        #  options[:namespace] << namespace
        #end
        opt.on '-m', '--match TEXT', 'select tests by description' do |text|
          options[:match] << text 
        end
        opt.on '-I', '--loadpath PATH',  'add to $LOAD_PATH' do |path|
          paths = path.split(/[:;]/)
          options[:loadpath].concat(paths)
        end
        opt.on "-r FILE" , 'require file(s) (before doing anything else)' do |files|
          files = files.split(/[:;]/)
          options[:requires].concat(files)
        end
        #opt.on('-o', '--output DIRECTORY', 'log directory'){ |dir|
        #  options[:output] = dir
        #}
        opt.on_tail("--[no-]ansi" , 'turn on/off ANSI colors'){ |v| $ansi = v }
        opt.on_tail("--debug" , 'turn on debugging mode'){ $DEBUG = true }
        #opt.on_tail("--about" , 'display information about lemon'){
        #  puts "Ruby Test v#{VERSION}"
        #  puts "#{COPYRIGHT}"
        #  exit
        #}
        opt.on_tail('-h', '--help', 'display this help message'){
          puts opt
          exit
        }
      end.parse!(argv)

      files = argv
      files = files.map{ |f| Dir[f] }.flatten
      files = files.map{ |f| File.directory?(f) ? Dir[File.join(f, '**/*.rb')] : f }
      files = files.flatten.uniq
      files = files.map{ |f| File.expand_path(f) }

      return files, options
    end

    #
    def self.cli_loadrc(files, options)
      if file = Dir[RC_GLOB].first
        load File.expand_path(file)
      end

      loadpath = options.delete(:loadpath) || ['lib']  # + ['lib'] ?
      requires = options.delete(:requires) || []

      loadpath.each{ |path| $LOAD_PATH.unshift(path) }
      requires.each{ |path| require(path) }

      files.each{ |path| require(path) }
    end

  end

end
