
require 'date'
require File.join(File.dirname(__FILE__), 'lib/bottomline/version')

Gem::Specification.new do |s|
  s.name = 'bottomline'
  s.version = BottomLine::VERSION
  s.authors = 'Peter Ohler'
  s.date = Date.today.to_s
  s.email = 'peter@ohler.com'
  s.homepage = 'https://github.com/ohler55/bottomline'
  s.summary = 'Accounting Application'
  s.description = 'A simple accounting application.'
  s.licenses = ['MIT']

  s.files = Dir["{lib/**/*.rb}"] + ['LICENSE', 'README.md', 'CHANGELOG.md']
  s.test_files = Dir["test/**/*.rb"]

  s.extra_rdoc_files = ['README.md', 'CHANGELOG.md', 'LICENSE']
  s.rdoc_options = ['-t', 'BottomLine', '-m', 'README.md', '-x', '"test/*"', '-x']

  s.bindir = 'bin'
  s.executables << 'bottomline'

  s.required_ruby_version = '>= 2.6.4'

  s.add_development_dependency 'oj', '~> 3.9'
end
