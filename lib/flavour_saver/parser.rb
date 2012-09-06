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
      clause('EXPRESSION_START WHITESPACE? IDENTIFIER WHITESPACE? EXPRESSION_END') { |_,_,i,_,_| i }
    end

    finalize

  end
end
