require 'test/reporters/abstract'

module Test::Reporters

  # HTML Test Reporter
  #
  # This reporter is rather simplistic and rough at this point --in need
  # of some TLC. Also, it may move to the TAPOUT project rather than be
  # a built-in Ruby-Test reporter.
  #--
  # TODO: Make this more like a microformat and add timer info.
  #++
  class Html < Abstract

    #
    def begin_suite(suite)
      timer_reset

      @html = []
      @html << %[<html>]
      @html << %[<head>]
      @html << %[<title>Test Report</title>]
      @html << %[  <style>]
      @html << %[    html{ background: #fff; margin: 0; padding: 0; font-family: helvetica; }]
      @html << %[    body{ margin: 0; padding: 0;}]
      @html << %[    h3{color:#555;}]
      @html << %[    #main{ margin: 0 auto; color: #110; width: 600px; ]
      @html << %[           border-right: 1px solid #ddd; border-left: 1px solid #ddd; ]
      @html << %[           padding: 10px 30px; width: 500px; } ]
      @html << %[    .lemon{ color: gold; font-size: 22px; font-weight: bold; ]
      @html << %[            font-family: courier; margin-bottom: -15px;}]
      @html << %[    .tally{ font-weight: bold; margin-bottom: 10px; }]
      @html << %[    .omit{ color: cyan; }]
      @html << %[    .pass{ color: green; }]
      @html << %[    .fail{ color: red; }]
      @html << %[    .footer{ font-size: 0.7em; color: #666; margin: 20px 0; }]
      @html << %[  </style>]
      @html << %[</head>]
      @html << %[<body>]
      @html << %[<div id="main">]
      @html << %[<div class="lemon">R U B Y - T E S T</div>]
      @html << %[<h1>Test Report</h1>]
      @body = []
    end

    #
    def begin_case(tc)
      lines = tc.to_s.split("\n")
      title = lines.shift
      @body << "<h2>"
      @body << title
      @body << "</h2>"
      @body << "<div>"
      @body << lines.join("<br/>")
      @body << "</div>"
    end

    #
    def begin_unit(unit)
      if unit.respond_to?(:subtext)
        subtext = unit.subtext
        if @subtext != subtext
          @subtext = subtext
          @body << "<h3>"
          @body << "#{subtext}"
          @body << "</h3>"
        end
      end
    end

    #
    def pass(unit)
      @body << %[<li class="pass">]
      @body << "%s %s" % ["PASS", unit.to_s]
      @body << %[</li>]
    end

    #
    def fail(unit, exception)
      @body << %[<li class="fail">]
      @body << "%s %s" % ["FAIL", unit.to_s]
      @body << "<pre>"
      @body << "  FAIL #{clean_backtrace(exception)[0]}"
      @body << "  #{exception}"
      @body << "</pre>"
      @body << %[</li>]
    end

    #
    def error(unit, exception)
      @body << %[<li class="error">]
      @body << "%s %s" % ["ERROR", unit.to_s]
      @body << "<pre>"
      @body << "  ERROR #{exception.class}"
      @body << "  #{exception}"
      @body << "  " + clean_backtrace(exception).join("\n        ")
      @body << "</pre>"
      @body << %[</li>]
    end

    #
    def todo(unit, exception)
      @body << %[<li class="pending">]
      @body << "%s %s" % ["PENDING", unit.to_s]
      @body << %[</li>]
    end

    #
    def omit(unit, exception)
      @body << %[<li class="omit">]
      @body << "%s %s" % ["OMIT", unit.to_s]
      @body << %[</li>]
    end

    #
    def end_suite(suite)
      @html << ""
      @html << %[<div class="tally">]
      @html << tally
      @html << %[</div>]
      @html << ""

      @body << ""
      @body << %[<div class="footer">]
      @body << %[Generated by <a href="http://rubyworks.github.com/test">Lemon</a>]
      @body << %[on #{Time.now}.]
      @body << %[</div>]
      @body << ""
      @body << %[</div>]
      @body << %[</div>]
      @body << ""
      @body << %[</body>]
      @body << %[</html>]

      puts @html.join("\n")
      puts @body.join("\n")
    end

  private

    #
    def timer
      secs  = Time.now - @time
      @time = Time.now
      return "%0.5fs" % [secs.to_s]
    end

    #
    def timer_reset
      @time = Time.now
    end

  end

end
