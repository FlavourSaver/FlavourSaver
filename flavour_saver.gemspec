# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flavour_saver/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["James Harton"]
  gem.email         = ["james@resistor.io"]
  gem.description   = %q{FlavourSaver is a pure-ruby implimentation of the Handlebars templating language}
  gem.summary       = %q{Handlebars.js without the .js}
  gem.homepage      = "http://jamesotron.github.com/FlavourSaver/"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "flavour_saver"
  gem.require_paths = ["lib"]
  gem.version       = FlavourSaver::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'activesupport', '< 7.0'

  gem.add_dependency 'rltk', '~> 2.2.0'
  gem.add_dependency 'tilt'
end
