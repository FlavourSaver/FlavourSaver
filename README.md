# FlavourSaver

[Handlebars.js](http://handlebarsjs.com) without the `.js`

## License

FlavourSaver is Copyright (c) 2012 Sociable Limited and licensed under the terms
of the MIT Public License (see the LICENSE file included with this distribution
for more details).

## Installation

Add this line to your application's Gemfile:

    gem 'flavour_saver'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flavour_saver

## Usage

FlavourSaver provides an interface to the amazing
[Tilt](https://github.com/rtomayko/tilt) templating library, meaning that it
should work with anything that has Tilt support (Sinatra, Rails, etc)

## Status

FlavourSaver is in it's infancy, your pull requests are greatly appreciated.

Currently supported:

  - Expressions:
    - with object-paths (`{{some.method.chain}}`)
    - containing object-literals (`{{object.['index'].method}}`):
      Ruby's `:[](index)` method is called for literals, making FlavourSaver
      compatible with `Hash` and hashlike objects.
    - with list arguments (`{{method arg1 "arg2"}}`)
    - with hash arguments (`{{method foo=bar bar="baz"}}`)
    - with list and hash arguments (`{{method arg1 arg2 foo=bar bar="baz"}}`)
      provided that the hash is the last argument.
    - Comments (`{{! a comment}}`)
    - Expression output is HTML escaped
  - Safe expressions
    - Expressions wrapped in triple-stashes are not HTML escaped (`{{{an expression}}}`)
  - Block expressions
    - Simple API for adding block helpers.

Coming soon:
  - Partials

## Helpers

FlavourSaver implements the following helpers by default:

### #with

Yields it's argument into the context of the block contents:

```handlebars
{{#with person}}
  {{name}}
{{/with}}
```

### #each

Takes a single collection argument and yeilds the block's contents once 
for each member of the collection:

```handlebars
{{#each people}}
  {{name}}
{{/each}}
```

### #if

Takes a single argument and yields the contents of the block if that argument
is truthy.

```handlebars
{{#if person}}
  Hi {{person.name}}!
{{/if}}
```

It can also handle a special case `{{else}}` expression:

```handlebars
{{#if person}}
  Hi {{person.name}}!
{{else}}
  Nobody to say hi to.
{{/if}}
```

### #unless

Exactly the same is `#if` but backwards.

### this

In JavaScript this is a native keyword, in Ruby not-so-much. FlavourSaver's `this` helper
returns `self`:

```handlebars
{{#each names}}
  {{this}}
{{/each}}
```

### Adding additional helpers

Additional helpers can easy be added by calling `FS.register_helper`, eg:

```ruby
FS.register_helper(:people) do
  [
    { firstName: 'Yehuda', lastName: 'Katz' },
    { firstName: 'Carl', lastName: 'Lerche' },
    { firstName: 'Alan', lastName: 'Johnson' },
  ]
end
```

Block helpers can simply yield from the blocks body:

```ruby
FS.register_helper(:list) do |people|
  "<ul>\n  <li>#{people.join("</li>\n  <li>")}</li>\n</ul>"
end
```

So rendering the following template:

```handlebars
{{#list people}}{{firstName}} {{lastName}}{{/list}}
```

Would output:

```html
<ul>
  <li>Yehuda Katz</li>
  <li>Carl Lerge</li>
  <li>Alan Johnson</li>
</ul>
```

### Adding block helpers

Creating a block helper works exactly like adding a regular helper, except that
the helper implementation can call `yield.contents` one or more times, with an
optional argument setting the context of the block execution:

```ruby
FW.register_helper(:three_times) do
  yield.contents
  yield.contents
  yield.contents
end
```

Which when called with the following template:

```handlebars
{{#three_times}}
  hello
{{/three_times}}
```

would result in the following output:
```
  hello
  hello
  hello
```

Implementing a simple iterator is dead easy:

```ruby
FW.register_helper(:list_people) do |people|
  people.each do |person|
    yield.contents person
  end
end
```

Which could be used like so:

```handlebars
{{#list_people people}}
  <b>{{name}}<b><br />
  Age: {{age}}<br />
  Sex: {{sex}}<br />
{{/list_people}}
```

Block helpers can also contain an `{{else}}` statement, which, when used creates
a second set of block contents (called `inverse`) which can be yielded to the output:

```ruby
FW.register_helper(:isFemale) do |person,&block|
  if person.sex == 'female'
    block.call.contents
  else
    block.call.inverse
  end
end
```

You can also register an existing method:

```ruby
def isFemale(person)
  if person.sex == 'female'
    yield.contents
  else
    yield.inverse
  end
end

FW.register_helper(method(:isFemale))
```

Which could be used like so:

```handlebars
{{#isFemale person}}
  {{person.name}} is female.
{{else}}
  {{person.name}} is male.
{{/isFemale}}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
