# FlavourSaver

[Handlebars.js](http://handlebarsjs.com) without the `.js`

[![Build Status](https://travis-ci.org/jamesotron/FlavourSaver.png)](https://travis-ci.org/jamesotron/FlavourSaver)
[![Dependency Status](https://gemnasium.com/jamesotron/FlavourSaver.png)](https://gemnasium.com/jamesotron/FlavourSaver)
[![Code Climate](https://codeclimate.com/github/jamesotron/FlavourSaver.png)](https://codeclimate.com/github/jamesotron/FlavourSaver)

## WAT?

FlavourSaver is a ruby-based implementation of the [Handlebars.js](http://handlebars.js)
templating language. FlavourSaver supports Handlebars template rendering natively on
Rails and on other frameworks (such as Sinatra) via Tilt.

Please use it, break it, and send issues/PR's for improvement.

## Caveat

FlavourSaver is used in production by a lot of folks, none of whom are me.  As
I don't use FlavourSaver in my daily life I will not be responding to issues
unless they have a corresponding PR.  If you'd like to take over maintaining
this project then get in contact.

## License

FlavourSaver is Copyright (c) 2013 Resistor Limited and licensed under the terms
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

  - Full support of Mustache and Handlebars templates.
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
    - Block expressions with inverse blocks
    - Inverse blocks
  - Partials
  - Raw content (`{{{{raw}}}} not parsed or validated {{{{/raw}}}}`)
  - Subexpressions (`{{sum 1 (sum 1 1)}}` returns `3`)

## Helpers

FlavourSaver implements the following helpers by default:

### #with

Yields its argument into the context of the block contents:

```handlebars
{{#with person}}
  {{name}}
{{/with}}
```

### #each

Takes a single collection argument and yields the block's contents once
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

### log

Writes log output.  The destination can be changed by assigning a `Logger` instance to
`FlavourSaver.logger=`.  On Rails `FlavourSaver.logger` automatically points at
`Rails.logger`.

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

### Subexpressions

You can use a subexpression as any value for a helper, and it will be executed before it is ran. You can also nest them, and use them in assignment of variables. 

Below are some examples, utilizing a "sum" helper than adds together two numbers.

```
{{sum (sum 5 10) (sum 2 (sum 1 4))}}
#=> 22

{{#if (sum 1 2) > 2}}its more{{/if}}
#=> its more

{{#student_heights size=(sum boys girls)}}
```

### Raw Content

Sometimes you don't want a section of content to be evaluted as handlebars, such as when you want to display it in a page that renders with handlebars. FlavourSaver offers a `raw` helper, that will allow you to pass anything through wrapped in those elements, and it will not be evaluated. 

```
{{{{raw}}}}
{{if} this tries to parse, it will break on syntax
{{{{/raw}}}}
=> {{if} this tries to parse, it will break on syntax
```

Its important to note that while this looks like a block helper, it is not in practice. This is why you must omit the use of a `#` when writing it. 

### Using Partials

Handlebars allows you to register a partial either as a function or a string template with
the engine before compiling, FlavourSaver retains this behaviour (with the notable exception
of within Rails - see below).

To register a partial you call `FlavourSaver.register_partial` with a name and a string:

```ruby
FlavourSaver.register_partial(:my_partial, "{{this}} is a partial")
```

You can then use this partial within your templates:

```handlebars
{{#each people}}{{> my_partial this}}{{/each}}
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

## Using the Tilt Interface Directly

You can use the registered Tilt interface directly to render template strings with a hash of template variables.

The Tilt template's `render` method expects an object that can respond to messages using dot notation. In the following example, the template variable `{{foo}}` will result in a call to `.foo` on the `data` object. For this reason the `data` object can't be a simple hash. A model would work, but if you have a plain old Ruby hash, use it to create a new OpenStruct object, which will provide the dot notation needed.

```ruby
template = Tilt['handlebars'].new { "{{foo}} {{bar}}" }
data = OpenStruct.new foo: "hello", bar: "world"

template.render data # => "hello world"
```

### Special behaviour of Handlebars' partial syntax

In Handlebars.js all partial templates must be pre-registered with the engine before they are
able to be used.  When running inside Rails FlavourSaver modifies this behaviour to use Rails'
render partial helper:

```handlebars
{{> my_partial}}
```

Will be translated into:

```ruby
render :partial => 'my_partial'
```

Handlebars allows you to send a context object into the partial, which sets the execution
context of the partial.  In Rails this behaviour would be confusing and non-standard, so
instead any argument passed to the partial is evaluated and passed to the partial's
`:object` argument:

```handlebars
{{> my_partial my_context}}
```

```ruby
render :partial => 'my_partial', :object => my_context
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
