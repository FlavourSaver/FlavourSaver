require 'rltk'
require 'rltk/ast'

module FlavourSaver
  Node       = Class.new(RLTK::ASTNode)
  class OutputNode < Node
    value :value, String
  end
  class ExpressionNode < Node
    # child :method, [IdentifierNode]
    value :method, Array
    value :arguments, Array
    value :block, Array
  end

  class Parser < RLTK::Parser

    production(:expression) do
      clause('EXPRESSIONSTART WHITESPACE? IDENTIFIER WHITESPACE? EXPRESSIONEND') { |_,_,i,_,_| i }
    end

    finalize

  end
end
