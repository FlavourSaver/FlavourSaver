module FlavourSaver
  UnknownNodeTypeException = Class.new(StandardError)
  UnknownContextException  = Class.new(StandardError)
  class Runtime

    def self.run(ast, context) 
      self.new(ast,context).to_s
    end

    def initialize(ast, context)
      @ast = ast
      @context = context
    end

    def to_s
      evaluate_node(@ast)
    end

    def evaluate_node(node)
      case node
      when TemplateNode
        node.items.map { |n| evaluate_node(n) }.join ''
      when OutputNode
        node.value
      when StringNode
        node.value
      when ExpressionNode
        evaluate_expression(node)
      when CallNode
        evaluate_call(node)
      else
        raise UnknownNodeTypeException, "Don't know how to deal with a node of type #{node.class.to_s.inspect}."
      end
    end

    def evaluate_call(call, context=@context)
      case call
      when ParentCallNode
        # how do I make a call stack, foo?
      when LiteralCallNode
        context.send(:[], call.name)
      else
        context.send(call.name, *call.arguments.map { |a| evaluate_argument(a) })
      end
    end

    def evaluate_argument(arg)
      if arg.is_a? Array
        arg.map{ |a| evaluate_node(a) }.join ''
      else
        evaluate_node(arg)
      end
    end

    def evaluate_expression(node,block=nil)
      node.method.inject(@context) do |result,call|
        result = evaluate_call(call, result)
      end
    end

  end
end
