require "flavour_saver/version"

module FlavourSaver

  autoload :Lexer,   'flavour_saver/lexer'
  autoload :Parser,  'flavour_saver/parser'
  autoload :Runtime, 'flavour_saver/runtime'
  autoload :Helpers, 'flavour_saver/helpers'

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
end
