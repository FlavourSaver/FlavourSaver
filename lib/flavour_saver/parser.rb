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
  class ParentCallNode < CallNode; end
  class ExpressionNode < Node
    child :method, [CallNode]
    child :block, [OutputNode]
  end
  class SafeExpressionNode < ExpressionNode ; end
  class CommentNode < Node
    value :comment, String
  end

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
      clause('expr_start expression_contents expr_end') { |e0,e1,_| e0.new(e1,[]) }
      clause('expr_start BANG COMMENT expr_end') { |_,_,e,_| CommentNode.new(e) }
    end

    production(:expr_start) do
      clause('EXPRST') { |_| ExpressionNode }
      clause('TEXPRST') { |_| SafeExpressionNode }
    end

    production(:expr_end) do
      clause('EXPRE') { |_| }
      clause('TEXPRE') { |_| }
    end

    production(:expression_contents) do
      clause('WHITE? call WHITE?') { |_,e,_| e }
    end

    production(:call) do
      clause('object_path') { |e| e }
      clause('object_path WHITE arguments') { |e0,_,e1| e0.last.arguments = e1; e0 }
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
      clause('DOT DOT FWSL IDENT') { |_,_,_,e| ParentCallNode.new(e, []) }
      clause('DOT DOT FWSL LITERAL') { |_,_,_,e| ParentCallNode.new(e, []) }
    end

    finalize

  end
end
