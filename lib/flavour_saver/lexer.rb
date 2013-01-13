require 'rltk'

module FlavourSaver
  class Lexer < RLTK::Lexer

    rule /{{{/, :default do
      push_state :expression
      :TEXPRST
    end

    rule /{{/, :default do
      push_state :expression
      :EXPRST
    end

    rule /#/, :expression do
      :HASH
    end

    rule /\//, :expression do
      :FWSL
    end

    rule /&/, :expression do
      :AMP
    end

    rule /\^/, :expression do
      :HAT
    end

    rule /@/, :expression do
      :AT
    end

    rule />/, :expression do
      :GT
    end

    rule /([1-9][0-9]*(\.[0-9]+)?)/, :expression do |n|
      [ :NUMBER, n ]
    end

    rule /true/, :expression do |i|
      [ :BOOL, true ]
    end

    rule /false/, :expression do |i|
      [ :BOOL, false ]
    end

    rule /\!/, :expression do
      push_state :comment
      :BANG
    end

    rule /([^}}]*)/, :comment do |comment|
      pop_state
      [ :COMMENT, comment ]
    end

    rule /else/, :expression do
      :ELSE
    end

    rule /([A-Za-z]\w*)/, :expression do |name|
      [ :IDENT, name ]
    end

    rule /\./, :expression do 
      :DOT
    end

    rule /\=/, :expression do
      :EQ
    end

    rule /"/, :expression do
      push_state :string
    end
    
    rule /(\\"|[^"])*/, :string do |str|
      [ :STRING, str ]
    end

    rule /"/, :string do
      pop_state
    end

    # Handlebars allows methods with hyphens in them. Ruby doesn't, so
    # we'll assume you're trying to index the context with the identifier
    # and call the result.
    rule /([A-Za-z][a-z0-9_-]*[a-z0-9])/, :expression do |str|
      [ :LITERAL, str ]
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
      :WHITE
    end

    rule /}}}/, :expression do
      pop_state
      :TEXPRE
    end

    rule /}}/, :expression do
      pop_state
      :EXPRE
    end

    rule /.*?(?={{|\z)/m, :default do |output|
      [ :OUT, output ]
    end
  end
end
