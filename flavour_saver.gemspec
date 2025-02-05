# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flavour_saver/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Clayton Passmore", "James Harton"]
  gem.email         = ["ctpassmore+flavoursaver@gmail.com"]
  gem.description   = %q{FlavourSaver is a pure-ruby implimentation of the Handlebars templating language}
  gem.summary       = %q{Handlebars.js without the .js}
  gem.homepage      = "http://github.com/FlavourSaver/FlavourSaver"
  gem.license       = "MIT"
  gem.metadata      = {
    "bug_tracker_uri"   => "http://github.com/FlavourSaver/FlavourSaver/issues",
    "changelog_uri"     => "http://github.com/FlavourSaver/FlavourSaver/blob/master/CHANGELOG.md",
    "homepage_uri"      => "http://github.com/FlavourSaver/FlavourSaver",
    "source_code_uri"   => "http://github.com/FlavourSaver/FlavourSaver",
  }

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "flavour_saver"
  gem.require_paths = ["lib"]
  gem.version       = FlavourSaver::VERSION

  gem.required_ruby_version = ">= 2.7.0"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "activesupport", "< 7.2"

  gem.add_dependency "rltk", "< 3.0"
  gem.add_dependency "tilt", "~> 2.6"
end
