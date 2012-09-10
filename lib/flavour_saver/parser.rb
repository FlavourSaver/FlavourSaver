require 'rltk'
require 'rltk/ast'
require 'flavour_saver/nodes'

module FlavourSaver
  class Parser < RLTK::Parser

    class UnbalancedBlockError < StandardError; end

    class Environment < RLTK::Parser::Environment
      attr_accessor :blocks
      
      def initialize
        self.blocks = []
      end

      def open_block(node)
        self.blocks << node
        node
      end

      def close_block(node)
        block = blocks.select { |n| n.name == node.name }.last
        if block
          block.closed_by(node)
          self.blocks.delete(block)
        else
          raise UnbalancedBlockError, "Unable to find matching block opening when evaluating \"/#{node.name}\"."
        end
        node
      end

      def after_parse
        blocks.each do |node|
          raise UnbalancedBlockError, "Unable to find a matching close expression for \"##{node.name}\"."
        end
      end
    end

    def self.parse(tokens, opts={})
      opts = build_parse_opts(opts)
      super(tokens,opts).tap do |r|
        opts[:env].after_parse
      end
    end

    left :DOT
    right :EQ

    production(:template) do
      clause('template_item') { |i| TemplateNode.new([i]) }
      clause('template template_item') { |t,i| t.items << i; t }
      clause('') { TemplateNode.new([]) }
    end

    production(:template_item) do
      clause('output') { |e| e }
      clause('expression') { |e| e }
    end

    production(:output) do
      clause('OUT') { |o| OutputNode.new(o) }
    end

    production(:expression) do
      clause('expr')          { |e| ExpressionNode.new(e) }
      clause('expr_comment')  { |e| CommentNode.new(e) }
      clause('expr_safe')     { |e| SafeExpressionNode.new(e) }
      clause('expr_bl_start') { |e| open_block BlockStartExpressionNode.new([e],[]) }
      clause('expr_bl_end')   { |e| close_block BlockCloseExpressionNode.new([e]) }
      clause('expr_else')     { |_| InverseNode.new }
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
      clause('EXPRST HASH WHITE? IDENT WHITE? EXPRE') { |_,_,_,e,_,_| CallNode.new(e,[]) }
      clause('EXPRST HASH WHITE? IDENT WHITE arguments EXPRE') { |_,_,_,e,_,a,_| CallNode.new(e,a) }
    end

    production(:expr_bl_end) do
      clause('EXPRST FWSL WHITE? IDENT WHITE? EXPRE') { |_,_,_,e,_,_| CallNode.new(e,[]) }
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
