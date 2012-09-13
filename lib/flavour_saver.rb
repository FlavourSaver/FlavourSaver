require "flavour_saver/version"
require 'tilt'

module FlavourSaver

  autoload :Lexer,          'flavour_saver/lexer'
  autoload :Parser,         'flavour_saver/parser'
  autoload :Runtime,        'flavour_saver/runtime'
  autoload :Helpers,        'flavour_saver/helpers'
  autoload :Template,       'flavour_saver/template'
  autoload :NodeCollection, 'flavour_saver/node_collection'

  module_function

  def lex(template)
    Lexer.lex(template)
  end

  def parse(tokens)
    Parser.parse(tokens)
  end

  def evaluate(template,context)
    context.extend(Helpers)
    Runtime.run(parse(lex(template)), context)
  end

  def register_partial(*args,&b)
    Helpers.register_partial(*args,&b)
  end

  Tilt.register(Template, 'handlebars', 'hbs')
end

FS = FlavourSaver
