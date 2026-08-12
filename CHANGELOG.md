# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 4.0.2

* Bump locked dependency versions

## 4.0.1

### Security

* Fixed arbitrary code execution via template method dispatch
  ([GHSA-98g2-gr9f-f85r](https://github.com/FlavourSaver/FlavourSaver/security/advisories/GHSA-98g2-gr9f-f85r)).
  A bare Handlebars identifier was dispatched to the rendering context with
  `public_send`, and Ruby's metaprogramming methods are public on every object, so a
  template containing `{{instance_eval "..."}}` executed arbitrary Ruby in the host
  process. Anyone able to author or edit a template could run code as the application.

  **All releases up to and including 4.0.0 are affected.** The fix for OSVDB #110796
  guarded dispatch with `respond_to?`. That never blocked public `Object` methods, so
  `{{instance_eval "..."}}` was reachable before and after it, and it could be sidestepped
  entirely with `{{send "system" "ls"}}`. It stopped `{{system "ls"}}` only for context
  objects that report their methods honestly — against a proxy or delegator that
  overreports `respond_to?`, that payload kept working in every release. This release is
  what closes it.

  Reported by Arpit Jain ([@arpitjain099](https://github.com/arpitjain099)).

### Changed

* Templates may now only dispatch to methods the application deliberately made
  available: registered helpers, locals, FlavourSaver's own block helpers, and the
  context object's own API. Anything else — Ruby's inherited object surface, methods
  a framework has mixed into `Object`, and FlavourSaver's internal plumbing — raises
  `FlavourSaver::ForbiddenMethodException`, a subclass of `UnknownHelperException`, so
  existing rescue clauses continue to catch it.

  Templates using `{{class}}`, `{{hash}}`, `{{method}}`, `{{display}}` and similar will
  now raise instead of rendering. Such templates could not have been working correctly:
  `Helpers::Decorator` inherits those methods, so its own implementation already shadowed
  any same-named method on the context object — `{{hash}}` returned an object digest and
  `{{display}}` printed the decorator to stdout rather than returning your data.

  Context methods sharing a name with a *private* `Kernel` method — `format`, `open`,
  `select`, `print`, `test`, `load` and around sixty others — are unaffected and continue
  to dispatch as before.

  To read a data field named after an `Object` method, use the segment literal syntax
  (`{{[hash]}}`), which resolves through `Decorator#[]` and so needs a hash-like context,
  or register an explicit helper.

## 4.0.0

### Added

* Added Ruby 4.0 to the test matrix

### Removed

* Dropped support for Ruby 2.7 and 3.0

## 3.0.0

### Added

* Ruby 3.2, 3.3, and 3.4 added to the test matrix

### Changed

* Bumped locked dependency versions

### Fixed

* Handle paths with array indices called on nil context objects (#63)

### Removed

* Dropped support for Ruby 2.6

## 2.0.2

### Fixed

* Deprecation warning for template handler (#59)

### Changed

* Relaxed version constraint on activesupport dependency (#60)

## 2.0.1

### Fixed

* Ability to dereference arrays at a specific index (#57)

## 2.0.0

### Breaking Changes

* The #if and #unless helpers now treat zero as falsey (#54, #55)
* The #unless helper now treats empty objects as falsey (#55)
* Using #each on a hash now yields the value instead of an array of key, value (#52)

### Added

* Support for @root object (#49)
* Support for @key object inside #each blocks with Hashes (#52)

### Fixed

* Lex number literals that start with 0 (#53)

## 1.0.0

### Added

* Ruby 3.0 and 3.1 support

### Changed

* The gem is now maintained by the FlavourSaver organization

### Removed

* Dropped support for Ruby 1.9, 2.0, 2.1, 2.2, 2.3, and 2.4

