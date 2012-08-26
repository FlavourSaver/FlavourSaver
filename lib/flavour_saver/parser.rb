require 'rltk'
require 'rltk/ast'

module FlavourSaver
  Node       = Class.new(RLTK::ASTNode)
  class OutputNode < Node
    value :value, String
  end
  class IdentifierNode < Node
    value :name, String
  end
  class ExpressionNode < Node
    # child :method, [IdentifierNode]
    value :method, Array
    value :arguments, Array
    value :block, Array
  end

  class Parser < RLTK::Parser

    production(:template) do
      clause('template_item') { |t| [t] }
      clause('template_item template_item') { |t0,t1| t0 + t1 }
    end

    production(:template_item) do
      clause('output') { |o| o }
      clause('expression') { |e| e }
    end

    production(:output) do
      clause('OUTPUT') { |o| OutputNode.new(o) }
    end

    production(:expression) do
      # clause('EXPRESSION_START optional_whitespace object_path optional_whitespace EXPRESSION_END') do |_,_,i,_,_|
      #   ExpressionNode.new(i, [])
      # end
      clause('EXPRESSION_START object_path EXPRESSION_END') do |_,i,_|
        ExpressionNode.new(i, [])
      end
    end

    production(:optional_whitespace) do
      clause('') {}
      clause('WHITESPACE') { |_| }
    end

    production(:object_path) do
      clause('IDENTIFIER') { |i| [i] }
      clause('IDENTIFIER DOT object_path') { |i0,_,i1| [i0] + i1 }
    end

    finalize

  end
end
