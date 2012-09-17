# FlavourSaver

[Handlebars.js](http://handlebarsjs.com) without the `.js`

## WAT?

FlavourSaver is a ruby-based implementation of the [Handlebars.js](http://handlebars.js)
templating language. FlavourSaver supports Handlebars template rendering natively on 
Rails and on other frameworks (such as Sinatra) via Tilt.

Please use it, break it, and send issues/PR's for improvement.

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
should work with anything that has Tilt support (Sinatra, etc) and has a 
native Rails template handler.

## Status

FlavourSaver is in its infancy, your pull requests are greatly appreciated.

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

In JavaScript `this` is a native keyword, in Ruby not-so-much. FlavourSaver's `this` helper
returns `self`:

```handlebars
{{#each names}}
  {{this}}
{{/each}}
```

### Adding additional helpers

Additional helpers can easy be added by calling `FS.register_helper`, eg:

```ruby
FS.register_helper(:whom) { 'world' }
```

Now if you were to render the following template:

```handlebars
<h1>Hello {{whom}}!</h1>
```

You would receive the following output:

```html
<h1>Hello world!</h1>
```

### Adding block helpers

Creating a block helper works exactly like adding a regular helper, except that
the helper implementation can call `yield.contents` one or more times, with an
optional argument setting the context of the block execution:

```ruby
FS.register_helper(:three_times) do
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
FS.register_helper(:list_people) do |people|
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
FS.register_helper(:isFemale) do |person,&block|
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

FS.register_helper(method(:isFemale))
```

Which could be used like so:

```handlebars
{{#isFemale person}}
  {{person.name}} is female.
{{else}}
  {{person.name}} is male.
{{/isFemale}}
```

## Using with Rails

One potential gotcha of using FlavourSaver with Rails is that FlavourSaver doesn't let you
have any access to the controller's instance variables. This is done to maintain compatibility
with the original JavaScript implementation of Handlebars so that templates can be used on
both the server and client side without any change.

When accessing controller instance variables you should access them by way of a helper method
or a presenter object.

For example, in `ApplicationController.rb` you may have a `before_filter` which authenticates
the current user's session cookie and stores it in the controller's `@current_user` instance
variable.

To access this variable you could create a simple helper method in `ApplicationHelpers`:

```ruby
def current_user
  @current_user
end
```

Which would mean that you are able to access it in your template:

```handlebars
{{#if current_user}}
  Welcome back, {{current_user.first_name}}!
{{/if}}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
