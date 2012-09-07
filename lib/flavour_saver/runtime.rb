require 'cgi'

module FlavourSaver
  UnknownNodeTypeException = Class.new(StandardError)
  UnknownContextException  = Class.new(StandardError)
  class Runtime

    def self.run(ast, context) 
      self.new(ast,context).to_s
    end

    def initialize(ast, context, parent=nil)
      @ast = ast
      @context = context
      @parent = parent
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
      raise UnknownContextException, "No parent context in which to evaluate the parentiness of the context"
    end

    def evaluate_call(call, context=@context)
      case call
      when ParentCallNode
        parent.evaluate_call(call,context)
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
