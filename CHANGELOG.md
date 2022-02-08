# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

* Support for @root object
* Support for @key object inside #each blocks with Hashes

### Fixed

* Zero is now falsy in if/else conditions as it is in Handlebars.js
* Lex number literals that start with 0
* Hashes now work with #each blocks

## [1.0.0] - 2022-01-19

### Added

* Ruby 3.0 and 3.1 support

### Changed

* The gem is now maintained by the FlavourSaver organization

### Removed

* Dropped support for Ruby 1.9, 2.0, 2.1, 2.2, 2.3, and 2.4

