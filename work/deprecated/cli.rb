

module Test

  # Command line interface to test runner.
  #
  class CLI

    # Test configuration file can be in `etc/test.rb` or `config/test.rb`, or
    # `Testfile` or '.test` with optional `.rb` extension, in that order of 
    # precedence. To use a different file there is the -c/--config option.
    GLOB_CONFIG = '{etc/test.rb,config/test.rb,testfile.rb,testfile,.test.rb,.test}'

    # Convenience method for invoking the CLI.
    #
    # @return nothing
    def self.run(*argv)
      new.run(*argv)
    end

    # Initialize CLI instance.
    #
    # @return nothing
    def initialize
      require 'optparse'

      @config = {}
      @config_file = nil
      #@config = Test.configuration(true)
    end

    # Test run configuration.
    #
    # @return [Config]
    def config
      @config
    end

    # Run tests.
    #
    # @return nothing
    def run(argv=nil)
      argv = (argv || ARGV.dup)

      options.parse!(argv)

      config.files.replace(argv) unless argv.empty?

      config.apply_environment_overrides

      #Test.run(config)
      runner = Runner.new(config)
      begin
        success = runner.run
        exit -1 unless success
      rescue => error
        raise error if $DEBUG
        $stderr.puts('ERROR: ' + error.to_s)
        exit -1
      end
    end

    # Setup OptionsParser instance.
    #
    # @return [OptionParser]
    def options
      this = self

      OptionParser.new do |opt|
        opt.banner = "Usage: #{File.basename($0)} [options] [files ...]"

        #opt.separator "PRESET OPTIONS:"
        #pnames = profile_names
        #unless pnames.empty?
        #  pnames.each do |pname|
        #    opt.separator((" " * 40) + "* #{pname}")
        #  end
        #end
        #opt.separator "CONFIG OPTIONS:"

        opt.on '-f', '--format NAME', 'report format' do |name|
          config.format = name
        end
        opt.on '-y', '--tapy', 'shortcut for -f tapy' do
          config.format = 'tapy'
        end
        opt.on '-j', '--tapj', 'shortcut for -f tapj' do
          config.format = 'tapj'
        end

        # tempted to change -T
        opt.on '-t', '--tag TAG', 'select tests by tag' do |tag|
          config.tags.concat makelist(tag)
        end
        opt.on '-u', '--unit TAG', 'select tests by software unit' do |unit|
          config.units.concat makelist(unit)
        end
        opt.on '-m', '--match TEXT', 'select tests by description' do |text|
          config.match.concat makelist(text)
        end

        opt.on '-A', '--autopath', 'automatically add paths to $LOAD_PATH' do |paths|
          config.autopath = true
        end
        opt.on '-I', '--loadpath PATH', 'add given path to $LOAD_PATH' do |paths|
          #makelist(paths).reverse_each do |path|
          #  $LOAD_PATH.unshift path
          #end
          config.loadpath.concat makelist(paths)
        end
        opt.on '-C', '--chdir DIR', 'change directory before running tests' do |dir|
          config.chdir = dir
        end
        opt.on '-R', '--chroot', 'change to project root directory before running tests' do
          config.chdir = Config.root
        end
        opt.on '-r', '--require FILE', 'require file' do |file|
          #require file
          config.requires.concat makelist(file)
        end
        opt.on '-c', '--config FILE', "require local config file (immediately)" do |file|
          config.load_config(file)
        end
        #opt.on '-T', '--tests GLOB', "tests to run (if none given as arguments)" do |glob|
        #  config.files << glob
        #end
        opt.on '-V' , '--verbose', 'provide extra detail in reports' do
          config.verbose = true
        end
        #opt.on('--log PATH', 'log test output to path'){ |path|
        #  config.log = path
        #}
        opt.on("--[no-]ansi" , 'turn on/off ANSI colors'){ |v| $ansi = v }
        opt.on("--debug" , 'turn on debugging mode'){ $DEBUG = true }

        #opt.separator "COMMAND OPTIONS:"
        opt.on('--about' , 'display information about rubytest') do
          puts "Ruby Test v%s" % [Test.index['version']]
          Test.index['copyrights'].each do |c|
            puts "(c) %s %s (%s)" % c.values_at('year', 'holder', 'license')
          end
          exit
        end
        opt.on('--version' , 'display rubytest version') do
          puts Test::VERSION
          exit
        end
        opt.on('-h', '--help', 'display this help message'){
          puts opt
          exit
        }
      end
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
