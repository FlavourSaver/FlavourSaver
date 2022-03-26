# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.1]

### Fixed

* Ability to dereference arrays at a specific index (#57)

## [2.0.0]

### Breaking Changes

* The #if and #unless helpers now treat zero as falsey (#54, #55)
* The #unless helper now treats empty objects as falsey (#55)
* Using #each on a hash now yields the value instead of an array of key, value (#52)

### Added

* Support for @root object (#49)
* Support for @key object inside #each blocks with Hashes (#52)

### Fixed

* Lex number literals that start with 0 (#53)

## [1.0.0] - 2022-01-19

### Added

* Ruby 3.0 and 3.1 support

### Changed

* The gem is now maintained by the FlavourSaver organization

### Removed

* Dropped support for Ruby 1.9, 2.0, 2.1, 2.2, 2.3, and 2.4

