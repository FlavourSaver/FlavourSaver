require 'cgi'

module FlavourSaver
  UnknownNodeTypeException         = Class.new(StandardError)
  UnknownContextException          = Class.new(StandardError)
  InappropriateUseOfElseException  = Class.new(StandardError)
  class Runtime

    attr_accessor :context, :parent, :ast

    def self.run(ast, context, locals, helpers=[])
      self.new(ast, context, locals, helpers).to_s
    end

    def initialize(ast, context=nil, locals={}, helpers=[],parent=nil)
      @ast = ast
      @locals = locals
      @helpers = helpers
      @context = context
      @parent = parent
    end

    def to_s(tmp_context = nil)
      if tmp_context
        old_context = @context
        @context = tmp_context
        result = evaluate_node(@ast)
        @context = old_context
        result
      else
        evaluate_node(@ast)
      end
    end

    def strip(tmp_context = nil)
      self.to_s(tmp_context).gsub(/[\s\r\n]+/,' ').strip
    end

    def evaluate_node(node)
      case node
      when TemplateNode
        node.items.map { |n| evaluate_node(n) }.join('')
      when BlockExpressionNode
        evaluate_block(node).to_s
      when OutputNode
        node.value
      when StringNode
        node.value
      when SafeExpressionNode
        evaluate_expression(node).to_s
      when ExpressionNode
        CGI.escapeHTML(evaluate_expression(node).to_s)
      when CallNode
        evaluate_call(node)
      when Hash
        node.each do |key,value|
          node[key] = evaluate_argument(value)
        end
        node
      when CommentNode
        ''
      else
        raise UnknownNodeTypeException, "Don't know how to deal with a node of type #{node.class.to_s.inspect}."
      end
    end

    def parent
      raise UnknownContextException, "No parent context in which to evaluate the parentiness of the context" unless @parent
      @parent
    end

    def parent?
      !!@parent
    end

    def evaluate_call(call, context=context, &block)
      context = Helpers.decorate_with(context,@helpers,@locals) unless context.is_a? Helpers::Decorator
      case call
      when ParentCallNode
        parent.evaluate_call(call.to_callnode,&block)
      when LiteralCallNode
        context.send(:[], call.name, &block)
      else
        context.send(call.name, *call.arguments.map { |a| evaluate_argument(a) }, &block)
      end
    end

    def evaluate_argument(arg)
      if arg.is_a? Array
        arg.map{ |a| evaluate_node(a) }.first
      else
        evaluate_node(arg)
      end
    end

    def evaluate_expression(node, &block)
      result = node.method.inject(context) do |context,call|
        context = evaluate_call(call, context, &block)
      end
      result.respond_to?(:join) ? result.join('') : result
    end

    def evaluate_block(node,block_context=@context)
      call = node.method.first
      content_runtime = create_child_runtime(node.contents)
      alternate_runtime = create_child_runtime(node.alternate) if node.respond_to? :alternate
      evaluate_call(call, block_context) do
        BlockRuntime.new(block_context,content_runtime,alternate_runtime)
      end
    end

    def create_child_runtime(body=[])
      node = body.is_a?(TemplateNode) ? body : TemplateNode.new(body)
      Runtime.new(node,nil,@locals,@helpers,self)
    end

    def inspect
      "#<FlavourSaver::Runtime contents=#{@ast.inspect}>"
    end

    class BlockRuntime
      def initialize(block_context,content_runtime,alternate_runtime=nil)
        @block_context = block_context
        @content_runtime = content_runtime
        @alternate_runtime = alternate_runtime
      end

      def contents(context=@block_context)
        @content_runtime.to_s(context)
      end

      def inverse(context=@block_context)
        @alternate_runtime.to_s(context)
      end
    end

  end
end
