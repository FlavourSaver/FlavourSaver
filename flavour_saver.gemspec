# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flavour_saver/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["James Harton"]
  gem.email         = ["jamesotron@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "flavour_saver"
  gem.require_paths = ["lib"]
  gem.version       = FlavourSaver::VERSION

  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rspec-core'
  gem.add_development_dependency 'turnip'
  gem.add_development_dependency 'guard-bundler'

  gem.add_dependency 'rltk', '~> 2.2.0'
end
