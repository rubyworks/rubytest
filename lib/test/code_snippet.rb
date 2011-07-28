module Test

  #
  class CodeSnippet

    def self.cache(file)
      @cache ||= {}
      @cache[file] ||=  File.readlines(file)
    end

    #
    def self.from_backtrace(backtrace)
      backtrace.first =~ /(.+?):(\d+(?=:|\z))/ or return ""
      file, line = $1, $2.to_i
      new(file, line)
    end

    #
    def self.from_error(exception)
      backtrace = exception.backtrace
      from_backtrace(backtrace)
    end

    #
    def initialize(file, line)
      @file = file
      @line = line || 1
      @code = CodeSnippet.cache(file)
    end

    #
    attr :file

    #
    attr :line

    #
    attr :code

    #
    alias :source :code

    #
    def to_str
      code[line-1].strip
    end

    #
    #--
    # TODO: ensure proper alignment by zero-padding line numbers
    #++
    def to_s(radius=2)
      f = " %2s %0#{rng.last.to_s.length}d %s"
      r = range(radius)
      r.map do |n|
        f % [('=>' if n == line), n, code[n-1].chomp]
      end.join("\n")
    end

    #
    def to_a(radius=2)
      r = range(radius)
      r.map do |n|
        code[n-1].chomp
      end
    end

    #
    def to_omap(radius=2)
      a = []
      r = range(radius)
      r.each do |n|
        a << {n => code[n-1].chomp}
      end
      a
    end

    #
    def succ
      line += 1
    end

  private

    #
    def range(radius)
      [line - radius, 1].max..[line + radius, source.length].min
    end

  end

end
