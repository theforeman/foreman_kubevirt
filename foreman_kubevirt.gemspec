require File.expand_path('lib/foreman_kubevirt/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'foreman_kubevirt'
  s.version     = ForemanKubevirt::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Moti Asayag']
  s.email       = ['masayag@redhat.com']
  s.homepage    = 'http://TODO'
  s.summary     = 'Kubevirt as compute resource for The Foreman.'
  # also update locale/gemspec.rb
  s.description = 'This gem provides Kubevirt as compute resource for The Foreman.'
  s.files       = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files  = Dir['test/**/*']

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rubocop'

  s.add_dependency('fog-kubevirt', '0.1.8')
end
