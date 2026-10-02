# FlavourSaver

[![Gem Version](https://badge.fury.io/rb/flavour_saver.svg)](https://rubygems.org/gems/flavour_saver)
[![CI](https://github.com/FlavourSaver/FlavourSaver/actions/workflows/ci.yml/badge.svg)](https://github.com/FlavourSaver/FlavourSaver/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[Handlebars](https://handlebarsjs.com) templates in pure Ruby. Use the same templates on the server and in the browser.

- Works with Rails, and with Sinatra or anything else that uses [Tilt](https://github.com/jeremyevans/tilt)
- One runtime dependency (`tilt`), no native extensions
- Ruby 3.1+, tested on 3.1 through 4.0

## Installation

```ruby
# Gemfile
gem "flavour_saver"
```

## Quick start

```ruby
require "flavour_saver"

Person = Struct.new(:name, :admin)

FlavourSaver.evaluate("Hello {{name}}!", Person.new("Ana", true))
# => "Hello Ana!"
```

`FS` is an alias for `FlavourSaver`.

The context can be any object. Templates read its public methods: `{{name}}` calls `context.name`. Use a Struct, a `Data` class, a model or a presenter.

> [!NOTE]
> A plain Hash doesn't work as the context, because `{{name}}` calls a method. Hash values can be read with segment literals: `{{settings.[theme]}}` calls `settings["theme"]` (string keys only).

### With Tilt

```ruby
template = Tilt["handlebars"].new { "{{greeting}}, {{name}}!" }
template.render(Struct.new(:greeting, :name).new("Hi", "Ana"))
# => "Hi, Ana!"
```

`.hbs` and `.handlebars` files are registered with Tilt, so `Tilt.new("welcome.hbs")` works too.

### With Rails

Put templates in `app/views` with a `.hbs` or `.handlebars` extension. See [Rails](#rails).

## Syntax

| Syntax | Example |
| --- | --- |
| Expression (HTML-escaped) | `{{name}}` |
| Raw output | `{{{bio}}}` or `{{&bio}}` |
| Path | `{{author.name}}` |
| Array index / hash key | `{{posts.[0].title}}`, `{{settings.[theme]}}` |
| Parent context | `{{../title}}` |
| Root context | `{{@root.title}}` |
| Comment | `{{! hidden }}`, `{{!-- hidden --}}` |
| Section / inverted section | `{{#posts}}…{{/posts}}`, `{{^posts}}none{{/posts}}` |
| Helper with arguments | `{{link "Home" href="/"}}` |
| Subexpression | `{{sum 1 (sum 2 3)}}` |
| Partial | `{{> user_card author}}` |
| Raw block (not parsed) | `{{{{raw}}}} {{left as is}} {{{{/raw}}}}` |

## Built-in helpers

| Helper | Does |
| --- | --- |
| `#if` / `#unless` | Renders the block when the value is truthy / falsy. Supports `{{else}}`. `nil`, `false`, `0` and empty collections are falsy. |
| `#each` | Renders the block for each item. Exposes `@index`, `@first`, `@last`, and `@key` for hashes. |
| `#with` | Renders the block with the value as the context. |
| `this` | The current context. |
| `log` | Writes to `FlavourSaver.logger` at debug level. |

```handlebars
{{#each posts}}
  {{@index}}. {{title}}{{#if @last}} (latest){{/if}}
{{/each}}

{{#if author.admin}}
  Admin
{{else}}
  Member
{{/if}}
```

On Rails, `FlavourSaver.logger` is `Rails.logger`. Elsewhere, set one before using `log`:

```ruby
require "logger"
FlavourSaver.logger = Logger.new($stdout)
```

## Custom helpers

Register a helper with a block. Positional arguments come first; `key=value` arguments arrive as a final hash with symbol keys.

```ruby
FS.register_helper(:shout) { |text| text.upcase }
FS.register_helper(:greet) { |name, options| "#{options[:greeting]}, #{name}" }
```

```handlebars
{{shout "hi"}}                  {{! HI }}
{{greet "Ana" greeting="Hola"}} {{! Hola, Ana }}
```

Helper output is HTML-escaped. Return an `html_safe` string (from ActiveSupport) to skip escaping.

### Block helpers

A block helper takes the template block as `&block`. `block.call.contents` renders the main section, optionally with a new context. `block.call.inverse` renders the `{{else}}` section.

```ruby
FS.register_helper(:admins) do |people, &block|
  admins = people.select(&:admin)
  if admins.any?
    admins.map { |person| block.call.contents(person) }.join
  else
    block.call.inverse
  end
end
```

```handlebars
{{#admins people}}
  <li>{{name}}</li>
{{else}}
  <li>No admins</li>
{{/admins}}
```

You can also register a method. Inside a method, `yield` works the same way as `block.call`:

```ruby
def twice
  yield.contents * 2
end

FS.register_helper(method(:twice))
```

### Subexpressions

Wrap a helper call in parentheses to use its result as an argument:

```ruby
FS.register_helper(:sum) { |a, b| a + b }
```

```handlebars
{{sum (sum 5 10) (sum 2 3)}}     {{! 20 }}
{{chart total=(sum boys girls)}}
```

## Partials

```ruby
FS.register_partial(:user_card, "<b>{{name}}</b>")
```

```handlebars
{{#each people}}{{> user_card this}}{{/each}}
```

A partial can also be a block that receives the context and returns a string:

```ruby
FS.register_partial(:user_card) { |person| "<b>#{person.name}</b>" }
```

On Rails, partials come from your views instead. See below.

## Rails

FlavourSaver registers `.hbs` and `.handlebars` template handlers with Action View.

**No instance variables.** Templates can't see controller instance variables. This keeps them portable to Handlebars.js. Expose data through helper methods or a presenter:

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def current_user
    Current.user
  end
end
```

```handlebars
{{#if current_user}}
  Welcome back, {{current_user.first_name}}!
{{/if}}
```

**Partials use `render`.** You don't register partials in Rails. The partial syntax maps to Rails partials, and the argument is passed as `object:`:

| Template | Rails call |
| --- | --- |
| `{{> user_card}}` | `render partial: "user_card", object: <current context>` |
| `{{> user_card author}}` | `render partial: "user_card", object: author` |

## Errors

Invalid templates raise a subclass of `FlavourSaver::Error`:

```ruby
begin
  FS.evaluate("{{#if ok}}unclosed", context)
rescue FlavourSaver::Error => e
  # FlavourSaver::Parser::NotInLanguage, ::UnbalancedBlockError,
  # or FlavourSaver::Lexer::LexingError
end
```

## Security

A template can only call registered helpers and the public methods of its context. Methods every object inherits, like `send`, `instance_eval` or `class`, raise `FlavourSaver::ForbiddenMethodException`. Private methods like `system` and `eval` can't be reached at all. Even so, only pass objects you're comfortable exposing to template authors.

## Not supported yet

These Handlebars features don't parse or don't behave like Handlebars.js yet. Pull requests are welcome.

- Whitespace control (`{{~foo~}}`)
- `{{else if …}}` chains
- Block parameters (`{{#each items as |item|}}`)
- `{{else}}` inside `{{#each}}` and `{{#with}}`
- Inline partials, partial blocks, dynamic partials, and hash arguments on partials
- The `lookup` helper
- `./` paths

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/FlavourSaver/FlavourSaver/issues).

```sh
git clone https://github.com/FlavourSaver/FlavourSaver.git
cd FlavourSaver
bundle install
bundle exec rspec
```

Changes are listed in the [CHANGELOG](CHANGELOG.md).

## License

MIT. Copyright (c) 2013 Resistor Limited. See [LICENSE](LICENSE).
