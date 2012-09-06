require 'rltk'

module FlavourSaver
  class Lexer < RLTK::Lexer

    rule /{{/, :default do
      push_state :expression
      [ :EXPRESSION_START ]
    end

    rule /([A-Za-z]\w+)/, :expression do |name|
      [ :IDENTIFIER, name ]
    end

    rule /\s+/, :expression do
      [ :WHITESPACE ]
    end

    rule /}}/, :expression do
      pop_state
      [ :EXPRESSION_END ]
    end
  end
end
