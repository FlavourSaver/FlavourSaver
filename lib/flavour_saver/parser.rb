require 'rltk'
require 'rltk/ast'
require 'flavour_saver/nodes'

module FlavourSaver
  class Parser < RLTK::Parser

    class UnbalancedBlockError < StandardError; end

    class Environment < RLTK::Parser::Environment
      def push_block block
        blocks.push(block.name)
        block
      end

      def pop_block block
        b = blocks.pop
        raise UnbalancedBlockError, "Unable to find matching opening for {{/#{block.name}}}" if b != block.name
        block
      end

      def blocks
        @blocks ||= []
      end
    end

    left :DOT
    right :EQ

    production(:template) do
      clause('template_items') { |i| TemplateNode.new(i) }
    end

    empty_list(:template_items, [:output, :expression], 'WHITE?')

    production(:output) do
      clause('OUT') { |o| OutputNode.new(o) }
    end

    production(:expression) do
      clause('block_expression') { |e| e }
      clause('expr')          { |e| ExpressionNode.new(e) }
      clause('expr_comment')  { |e| CommentNode.new(e) }
      clause('expr_safe')     { |e| SafeExpressionNode.new(e) }
    end

    production(:block_expression) do
      clause('expr_bl_start template expr_else template expr_bl_end') { |e0,e1,_,e3,e2| BlockExpressionNodeWithElse.new([e0], e1,e2,e3) }
      clause('expr_bl_start template expr_bl_end') { |e0,e1,e2| BlockExpressionNode.new([e0],e1,e2) }
    end

    production(:expr_else) do
      clause('EXPRST ELSE EXPRE') { |_,_,_| }
    end

    production(:expr) do
      clause('EXPRST expression_contents EXPRE') { |_,e,_| e }
    end

    production(:expr_comment) do
      clause('EXPRST BANG COMMENT EXPRE') { |_,_,e,_| e }
    end

    production(:expr_safe) do
      clause('TEXPRST expression_contents TEXPRE') { |_,e,_| e }
    end

    production(:expr_bl_start) do
      clause('EXPRST HASH WHITE? IDENT WHITE? EXPRE') { |_,_,_,e,_,_| push_block CallNode.new(e,[]) }
      clause('EXPRST HASH WHITE? IDENT WHITE arguments EXPRE') { |_,_,_,e,_,a,_| push_block CallNode.new(e,a) }
    end

    production(:expr_bl_end) do
      clause('EXPRST FWSL WHITE? IDENT WHITE? EXPRE') { |_,_,_,e,_,_| pop_block CallNode.new(e,[]) }
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
      clause('LITERAL') { |e| LiteralCallNode.new(e, []) }
      clause('DOT DOT FWSL IDENT') { |_,_,_,e| ParentCallNode.new(e, []) }
      clause('DOT DOT FWSL LITERAL') { |_,_,_,e| ParentCallNode.new(e, []) }
    end

    finalize

  end
end
