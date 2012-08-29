require 'rltk'

module FlavourSaver
  class Lexer < RLTK::Lexer

    rule /{{{/, :default do
      push_state :expression
      [ :TRIPPLE_EXPRESSION_START ]
    end

    rule /{{/, :default do
      push_state :expression
      [ :EXPRESSION_START ]
    end

    rule /#/, :expression do
      [ :BLOCK_START ]
    end

    rule /\//, :expression do
      [ :BLOCK_END ]
    end

    rule /([A-Za-z]\w+)/, :expression do |name|
      [ :IDENTIFIER, name ]
    end

    rule /\./, :expression do 
      [ :DOT ]
    end

    rule /\=/, :expression do
      [ :ASSIGN ]
    end

    rule /"/, :expression do
      push_state :string
    end
    
    rule /([^"]+)/, :string do |str|
      [ :STRING, str ]
    end

    rule /"/, :string do
      pop_state
    end

    rule /\[/, :expression do
      push_state :segment_literal
    end

    rule /([^\]]+)/, :segment_literal do |l|
      [ :LITERAL, l ]
    end

    rule /]/, :segment_literal do
      pop_state
    end

    rule /\s+/, :expression do
      [ :WHITESPACE ]
    end

    rule /}}}/, :expression do
      pop_state
      [ :TRIPPLE_EXPRESSION_END ]
    end

    rule /}}/, :expression do
      pop_state
      [ :EXPRESSION_END ]
    end

    rule /[^{{]+/, :default do |output|
      [ :OUTPUT, output ]
    end
  end
end
