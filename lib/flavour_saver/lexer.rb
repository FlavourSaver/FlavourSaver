require 'rltk'

module FlavourSaver
  class Lexer < RLTK::Lexer

    rule /{{/, :default do
      push_state :expression
      [ :EXPRESSIONSTART ]
    end

    rule /([A-Za-z]\w+)/, :expression do |name|
      [ :IDENTIFIER, name ]
    end

    rule /\s+/, :expression do
      [ :WHITESPACE ]
    end

    rule /}}/, :expression do
      pop_state
      [ :EXPRESSIONEND ]
    end
  end
end
