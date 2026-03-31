Gem::Specification.new do |s|
  s.name        = 'rubytest'
  s.version     = '0.9.0'
  s.summary     = 'Ruby Universal Test Harness'
  s.description = 'Rubytest is a universal test harness for Ruby. It can handle any compliant ' \
                  'test framework, even running tests from multiple frameworks in a single pass.'

  s.authors     = ['Trans']
  s.email       = ['transfire@gmail.com']

  s.homepage    = 'https://github.com/rubyworks/rubytest'
  s.license     = 'BSD-2-Clause'

  s.required_ruby_version = '>= 3.1'

  s.files       = Dir['lib/**/*', 'bin/*', 'LICENSE.txt', 'README.md', 'HISTORY.md', 'demo/**/*']
  s.bindir      = 'bin'
  s.executables = ['rubytest']
  s.require_paths = ['lib']

  s.add_dependency 'ansi', '>= 1.5'

  s.add_development_dependency 'rake', '>= 13'
  s.add_development_dependency 'qed', '>= 2.9'
  s.add_development_dependency 'ae', '>= 1.8'
end
