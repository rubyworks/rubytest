module Test

  # Command line interface to test runner.
  #
  # TODO: Use `cli` based library instead of option parse.
  #
  class CLI

    #
    # Convenience method for invoking the CLI.
    #
    def self.run(*argv)
      new.run(*argv)
    end

    #
    # Initialize CLI instance.
    #
    def initialize
      require 'optparse'
    end

    #
    def config
      @config ||= Test.configuration
    end

    #
    # Run tests.
    #
    def run(argv=nil)
      begin
        require 'dotopts'
      rescue LoadError
      end

      argv = (argv || ARGV.dup)

      options.parse!(argv)

      config.files.replace(argv) unless argv.empty?

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

    # These options are parsed prior to any other options.
    #
    # TODO: Certain opitons should be parsed before others.
    #       Some aren't even useful if not, use as -R.
    def preoptions

    end

    #
    # Setup OptionsParser instance.
    #
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

        opt.on '-t', '--tag TAG', 'select tests by tag' do |tag|
          config.tags << tag
        end
        opt.on '-u', '--unit TAG', 'select tests by software unit' do |unit|
          config.units << unit
        end
        opt.on '-m', '--match TEXT', 'select tests by description' do |text|
          config.match << text 
        end

        opt.on '-A', '--autopath', 'automatically add paths to $LOAD_PATH' do |paths|
          config.autopath = true
        end
        opt.on '-I', '--loadpath PATH', 'add given path to $LOAD_PATH' do |paths|
          paths.split(/[:;]/).reverse_each do |path|
            $LOAD_PATH.unshift path
          end
        end
        #opt.on '-C', '--chdir DIR', 'change directory before running tests' do |dir|
        #  config.chdir = dir
        #end
        #opt.on '-R', '--chroot', 'change to project root directory before running tests' do |bool|
        #  config.chroot = bool
        #end
        opt.on '-r', '--require FILE', 'require file (immediately)' do |file|
          require file
        end
        opt.on '-c', '--config FILE', "require local config file" do |file|
          Config.require_config(file)
        end
        opt.on '-d' , '--details', 'provide extra detail in reports' do
          config.verbose = true
        end
        #opt.on('--log DIRECTORY', 'log directory'){ |dir|
        #  options[:log] = dir
        #}
        opt.on("--[no-]ansi" , 'turn on/off ANSI colors'){ |v| $ansi = v }
        opt.on("--debug" , 'turn on debugging mode'){ $DEBUG = true }

        #opt.separator "COMMAND OPTIONS:"
        #opt.on("--about" , 'display information about rubytest'){
        #  puts "Ruby Test v#{VERSION}"
        #  puts "#{COPYRIGHT}"
        #  exit
        #}
        opt.on('-h', '--help', 'display this help message'){
          puts opt
          exit
        }
      end
    end

  end

end
