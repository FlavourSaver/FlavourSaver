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
      clause('') { TemplateNode.new([]) }
    end

    # empty_list(:template_items, [:output, :expression], 'WHITE?')
    production(:template_items) do
      clause('template_item') { |i| [i] }
      clause('template_items template_item') { |i0,i1| i0 << i1 }
    end

    production(:template_item) do
      clause('raw_bl')     { |e| e }
      clause('output')     { |e| e }
      clause('expression') { |e| e }
    end

    production(:output) do
      clause('OUT') { |o| OutputNode.new(o) }
    end

    production(:raw_bl) do
      clause('RAWSTART RAWSTRING RAWEND') { |_,e,_| OutputNode.new(e) }
    end

    production(:expression) do
      clause('block_expression') { |e| e }
      clause('expr')          { |e| ExpressionNode.new(e) }
      clause('expr_comment')  { |e| CommentNode.new(e) }
      clause('expr_safe')     { |e| SafeExpressionNode.new(e) }
      clause('partial')       { |e| e }
    end

    production(:partial) do
      clause('EXPRST WHITE? GT WHITE? STRING WHITE? EXPRE') { |_,_,_,_,e,_,_| PartialNode.new(e,[]) }
      clause('EXPRST WHITE? GT WHITE? IDENT WHITE? EXPRE') { |_,_,_,_,e,_,_| PartialNode.new(e,[]) }
      clause('EXPRST WHITE? GT WHITE? IDENT WHITE? call WHITE? EXPRE') { |_,_,_,_,e0,_,e1,_,_| PartialNode.new(e0,e1,nil) }
      clause('EXPRST WHITE? GT WHITE? IDENT WHITE? lit WHITE? EXPRE') { |_,_,_,_,e0,_,e1,_,_| PartialNode.new(e0,[],e1) }
      clause('EXPRST WHITE? GT WHITE? LITERAL WHITE? EXPRE') { |_,_,_,_,e,_,_| PartialNode.new(e,[]) }
      clause('EXPRST WHITE? GT WHITE? LITERAL WHITE? call WHITE? EXPRE') { |_,_,_,_,e0,_,e1,_,_| PartialNode.new(e0,e1,nil) }
      clause('EXPRST WHITE? GT WHITE? LITERAL WHITE? lit WHITE? EXPRE') { |_,_,_,_,e0,_,e1,_,_| PartialNode.new(e0,[],e1) }
    end

    production(:block_expression) do
      clause('expr_bl_start template expr_else template expr_bl_end') { |e0,e1,_,e3,e2| BlockExpressionNodeWithElse.new([e0], e1,e2,e3) }
      clause('expr_bl_start template expr_bl_end') { |e0,e1,e2| BlockExpressionNode.new([e0],e1,e2) }
      clause('expr_bl_inv_start template expr_else template expr_bl_end') { |e0,e1,_,e3,e2| BlockExpressionNodeWithElse.new([e0], e2,e2,e1) }
      clause('expr_bl_inv_start template expr_bl_end') { |e0,e1,e2| BlockExpressionNodeWithElse.new([e0],TemplateNode.new([]),e2,e1) }
    end

    production(:expr_else) do
      clause('EXPRST WHITE? ELSE WHITE? EXPRE') { |_,_,_,_,_| }
      clause('EXPRST WHITE? HAT WHITE? EXPRE') { |_,_,_,_,_| }
    end

    production(:expr) do
      clause('EXPRST expression_contents EXPRE') { |_,e,_| e }
    end

    production(:subexpr) do
      clause('OPAR expression_contents CPAR') { |_,e,_| e }
    end

    production(:expr_comment) do
      clause('EXPRST BANG COMMENT EXPRE') { |_,_,e,_| e }
    end

    production(:expr_safe) do
      clause('TEXPRST expression_contents TEXPRE') { |_,e,_| e }
      clause('EXPRST AMP expression_contents EXPRE') { |_,_,e,_| e }
    end

    production(:expr_bl_start) do
      clause('EXPRST HASH WHITE? IDENT WHITE? EXPRE') { |_,_,_,e,_,_| push_block CallNode.new(e,[]) }
      clause('EXPRST HASH WHITE? IDENT WHITE arguments WHITE? EXPRE') { |_,_,_,e,_,a,_,_| push_block CallNode.new(e,a) }
    end

    production(:expr_bl_inv_start) do
      clause('EXPRST HAT WHITE? IDENT WHITE? EXPRE') { |_,_,_,e,_,_| push_block CallNode.new(e,[]) }
      clause('EXPRST HAT WHITE? IDENT WHITE arguments WHITE? EXPRE') { |_,_,_,e,_,a,_,_| push_block CallNode.new(e,a) }
    end

    production(:expr_bl_end) do
      clause('EXPRST FWSL WHITE? IDENT WHITE? EXPRE') { |_,_,_,e,_,_| pop_block CallNode.new(e,[]) }
    end

    production(:expression_contents) do
      clause('WHITE? call WHITE?') { |_,e,_| e }
      clause('WHITE? local WHITE?') { |_,e,_| [e] }
    end

    production(:call) do
      clause('object_path') { |e| e }
      clause('object_path WHITE arguments') { |e0,_,e1| e0.last.arguments = e1; e0 }
      clause('DOT') { |_| [CallNode.new('this', [])] }
    end

    production(:local) do
      clause('AT IDENT') { |_,e| LocalVarNode.new(e) }
    end

    production('arguments') do
      clause('argument_list') { |e| e }
      clause('argument_list WHITE hash') { |e0,_,e1| e0 + [e1] }
      clause('hash') { |e| [e] }
    end
    
    nonempty_list(:argument_list, [:object_path,:lit, :local, :subexpr], :WHITE)

    production(:lit) do
      clause('string') { |e| e }
      clause('number') { |e| e }
      clause('boolean') { |e| e }
    end

    production(:string) do
      clause('STRING') { |e| StringNode.new(e) }
      clause('S_STRING') { |e| StringNode.new(e) }
    end

    production(:number) do
      clause('NUMBER') { |n| NumberNode.new(n) }
    end

    production(:boolean) do
      clause('BOOL') { |b| b ? TrueNode.new(true) : FalseNode.new(false) }
    end

    production(:hash) do
      clause('hash_item') { |e| e }
      clause('hash WHITE hash_item') { |e0,_,e1| e0.merge(e1) }
    end

    production(:hash_item) do
      clause('IDENT EQ subexpr') { |e0,_,e1| { e0.to_sym => e1 } }
      clause('IDENT EQ string') { |e0,_,e1| { e0.to_sym => e1 } }
      clause('IDENT EQ number') { |e0,_,e1| { e0.to_sym => e1 } }
      clause('IDENT EQ object_path') { |e0,_,e1| { e0.to_sym => e1 } }
    end

    production(:object_sep) do
      clause('DOT') { |_| }
      clause('FWSL') { |_| }
    end

    nonempty_list(:object_path, :object, :object_sep)

    production(:object) do
      clause('IDENT') { |e| CallNode.new(e, []) }
      clause('LITERAL') { |e| LiteralCallNode.new(e, []) }
      clause('parent_call') { |e| e }
    end

    production(:parent_call) do
      clause('backtrack IDENT') { |i,e| ParentCallNode.new(e,[],i) }
      clause('backtrack LITERAL') { |i,e| ParentCallNode.new(e,[],i) }
    end

    production(:backtrack) do
      clause('DOT DOT FWSL') { |_,_,_| 1 }
      clause('backtrack DOT DOT FWSL') { |i,_,_,_| i += 1 }
    end

    finalize

  end
end
