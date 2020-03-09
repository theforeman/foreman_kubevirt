require File.expand_path('lib/foreman_kubevirt/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'foreman_kubevirt'
  s.version     = ForemanKubevirt::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Moti Asayag']
  s.email       = ['masayag@redhat.com']
  s.homepage    = 'https://github.com/theforeman/foreman_kubevirt'
  s.summary     = 'Provision and manage Kubevirt Virtual Machines from Foreman'
  # also update locale/gemspec.rb
  s.description = 'Provision and manage Kubevirt Virtual Machines from Foreman.'
  s.files       = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files  = Dir['test/**/*']

  s.add_development_dependency('rake', '~> 12.3')
  s.add_development_dependency('rubocop', '~> 0.80.0')

  s.add_dependency('fog-kubevirt', '~>1.3.3')
end
