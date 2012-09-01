require 'rltk'
require 'rltk/ast'

module FlavourSaver
  Node       = Class.new(RLTK::ASTNode)
  class OutputNode < Node
    value :value, String
  end
  class StringNode < Node
    value :value, String
  end
  class CallNode < Node
    value :name, String
    value :arguments, Array
  end
  class ExpressionNode < Node
    child :method, [CallNode]
    child :block, [OutputNode]
  end
  class SafeExpressionNode < ExpressionNode ; end

  class Parser < RLTK::Parser

    left :DOT
    right :EQ

    production(:template) do
      clause('template_item') { |i| [i] }
      clause('template template_item') { |t,i| t + [i] }
    end

    production(:template_item) do
      clause('output') { |e| e }
      clause('expression') { |e| e }
    end

    production(:output) do
      clause('OUT') { |o| OutputNode.new(o) }
    end

    production(:expression) do
      clause('EXPRST WHITE? call WHITE? EXPRE') { |_,_,e,_,_| ExpressionNode.new(e, []) }
      clause('EXPRST HASH WHITE? call WHITE? EXPRE template EXPRST FWSL WHITE? IDENTIFIER WHITE? EXPRE') { |_,_,_,e,_,_,t,_,_,_,_,_,_| ExpressionNode.new(e,t) }
      clause('TEXPRST WHITE? call WHITE? TEXPRE') { |_,_,e,_,_| SafeExpressionNode.new(e, []) }
    end

    production(:call) do
      clause('object_path') { |e| e }
      clause('object_path WHITE? arguments') { |e0,_,e1| e0.last.arguments = e1; e0 }
    end

    production('arguments') do
      clause('argument_list') { |e| e }
      clause('argument_list hash') { |e0,e1| e0 + [e1] }
      clause('hash') { |e| [e] }
    end

    nonempty_list(:argument_list, [:object_path, :string], :WHITE)

    production(:string) do
      clause('STRING') { |e| StringNode.new(e) }
    end

    production(:hash) do
      clause('hash_item') { |e| e }
      clause('hash WHITE hash_item') { |e0,_,e1| e0.merge(e1) }
    end

    production(:hash_item) do
      clause('IDENT EQ string') { |e0,_,e1| { e0.to_sym => e1 } }
      clause('IDENT EQ object_path') { |e0,_,e1| { e0.to_sym => e1 } }
    end

    nonempty_list(:object_path, :object, :DOT)

    production(:object) do
      clause('IDENT') { |e| CallNode.new(e, []) }
      clause('LITERAL') { |e| CallNode.new(e, []) }
    end

    finalize

  end
end
