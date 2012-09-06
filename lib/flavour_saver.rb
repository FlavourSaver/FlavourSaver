require "flavour_saver/version"

module FlavourSaver

  autoload :Lexer,   'flavour_saver/lexer'
  autoload :Parser,  'flavour_saver/parser'
  autoload :Runtime, 'flavour_saver/runtime'

  module_function

  def lex(template)
    Lexer.lex(template)
  end

  def parse(tokens)
    Parser.parse(tokens)
  end

  def evaluate
  end
end
