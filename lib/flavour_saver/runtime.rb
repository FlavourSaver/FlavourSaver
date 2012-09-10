require 'cgi'

module FlavourSaver
  UnknownNodeTypeException = Class.new(StandardError)
  UnknownContextException  = Class.new(StandardError)
  class Runtime

    attr_accessor :context, :parent

    def self.run(ast, context, locals, helpers=[])
      self.new(ast, context, locals, helpers).to_s
    end

    def initialize(ast, context=nil, locals={}, helpers=[])
      @ast = ast
      @locals = locals
      @helpers = helpers
      @context = context
    end

    def to_s
      evaluate_node(@ast)
    end

    def evaluate_node(node,block=[])
      case node
      when BlockCloseExpressionNode
        ''
      when TemplateNode
        result = ''
        pos = 0
        len = node.items.size
        while(pos < len)
          n = node.items[pos]
          if n.is_a? BlockStartExpressionNode
            blocknode = n
            blockbody = []
            pos += 1
            while (node.items[pos] != blocknode.closed_by)
              n = node.items[pos]
              blockbody << n
              pos += 1
            end
            result << evaluate_block(blocknode, blockbody).to_s
          else
            result << evaluate_node(n).to_s
            pos += 1
          end
        end
        result
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

    def evaluate_call(call, context=context, &block)
      context = Helpers.decorate_with(context,@helpers,@locals)
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
      r = node.method.inject(context) do |result,call|
        result = evaluate_call(call, result, &block)
      end
      r.respond_to?(:join) ? r.join('') : r
    end

    def evaluate_block(node,body=[])
      child = create_child_runtime(body)
      block = proc do |context|
        child.context = context
        result = child.to_s
        child.context = nil
        result
      end
      call = node.method.first
      evaluate_call(call, context, &block)
    end

    def create_child_runtime(body=[])
      Runtime.new(TemplateNode.new(body),nil,@locals,@helpers).tap { |r| r.parent = self }
    end

    def inspect
      "#<FlavourSaver::Runtime contents=#{@ast.inspect}>"
    end

  end
end
