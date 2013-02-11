module Test

  # Command line interface to test runner.
  #
  # TODO: Use `cli` based library instead of option parser?
  #
  class CLI

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
    end

    # Test run configuration.
    #
    # @return [Config]
    def config
      @config ||= Test.configuration
    end

    # Run tests.
    #
    # @return nothing
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

        opt.on '-t', '--tag TAG', 'select tests by tag' do |tag|
          config.tags.concat enlist(tag)
        end
        opt.on '-u', '--unit TAG', 'select tests by software unit' do |unit|
          config.units.concat enlist(unit)
        end
        opt.on '-m', '--match TEXT', 'select tests by description' do |text|
          config.match.concat enlist(text)
        end

        opt.on '-A', '--autopath', 'automatically add paths to $LOAD_PATH' do |paths|
          config.autopath = true
        end
        opt.on '-I', '--loadpath PATH', 'add given path to $LOAD_PATH' do |paths|
          #enlist(paths).reverse_each do |path|
          #  $LOAD_PATH.unshift path
          #end
          config.loadpath.concat enlist(paths)
        end
        #opt.on '-C', '--chdir DIR', 'change directory before running tests' do |dir|
        #  config.chdir = dir
        #end
        #opt.on '-R', '--chroot', 'change to project root directory before running tests' do |bool|
        #  config.chroot = bool
        #end
        opt.on '-r', '--require FILE', 'require file' do |file|
          #require file
          config.requires.concat pathlist(file)
        end
        opt.on '-c', '--config FILE', "require local config file (immediately)" do |file|
          Config.require_config(file)
        end
        opt.on '-V' , '--verbose', 'provide extra detail in reports' do
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

    # If given a String then split up at `:` and `;` markers.
    # Otherwise ensure the list is an Array and the entries are
    # all strings and not empty.
    #
    # @return [Array<String>]
    def enlist(list)
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
