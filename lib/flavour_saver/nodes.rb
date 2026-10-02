module FlavourSaver
  class Node
    # Fields are declared as either values (plain data) or children (nodes,
    # or arrays of nodes, which get their #parent set). The constructor takes
    # every value, then every child, positionally, inherited ones first.
    class << self
      def value(name, _type = nil)
        value_names << name
        attr_accessor name
      end

      def child(name, _type = nil)
        child_names << name
        attr_reader name
        ivar = :"@#{name}"
        define_method(:"#{name}=") do |node|
          Array(node).each { |n| n.parent = self } unless node.is_a?(Hash)
          instance_variable_set(ivar, node)
        end
      end

      def value_names
        @value_names ||= superclass.respond_to?(:value_names) ? superclass.value_names.dup : []
      end

      def child_names
        @child_names ||= superclass.respond_to?(:child_names) ? superclass.child_names.dup : []
      end
    end

    attr_accessor :parent

    def initialize(*fields)
      names = self.class.value_names + self.class.child_names
      raise ArgumentError, "#{self.class} takes at most #{names.size} fields" if fields.size > names.size
      names.each_with_index { |name, i| public_send(:"#{name}=", fields[i]) }
    end

    def values
      self.class.value_names.map { |name| public_send(name) }
    end

    def children
      self.class.child_names.map { |name| public_send(name) }
    end

    def ==(other)
      other.class == self.class && other.values == values && other.children == children
    end

    def inspect
      to_s.inspect
    end
  end

  class TemplateItemNode < Node; end

  class TemplateNode < Node
    child :items, [TemplateItemNode]

    def to_s
      items.join ""
    end
  end

  class OutputNode < TemplateItemNode
    value :value, String

    def to_s
      value
    end
  end

  class ValueNode < Node
    def to_s
      value.inspect
    end

    def inspect
      value.inspect
    end
  end

  class StringNode < ValueNode
    value :value, String
  end

  class NumberNode < ValueNode
    value :value, String
  end

  class BooleanNode < ValueNode
  end

  class TrueNode < BooleanNode
    value :value, TrueClass
  end

  class FalseNode < BooleanNode
    value :value, FalseClass
  end

  class CallNode < Node
    value :name, String
    value :arguments, Array

    def arguments_to_str(str = "")
      str = str.dup # RLTK magic?
      arguments.each do |arg|
        str << " "
        if arg.respond_to? :join
          str << arg.join(".")
        elsif arg.respond_to? :keys
          arg.each do |k, v|
            str << "#{k}: #{v.inspect}"
          end
        else
          str << arg.inspect
        end
      end
      str
    end

    def to_s
      arguments_to_str(name)
    end
  end

  class LocalVarNode < CallNode
    def to_s
      arguments_to_str("@#{name}")
    end
  end

  class LiteralCallNode < CallNode
    def to_s
      arguments_to_str("[#{name.inspect}]")
    end
  end

  class ParentCallNode < CallNode
    value :depth, Integer

    def to_callnode
      CallNode.new(name, arguments)
    end

    def to_s
      "#{"../" * depth}#{super}"
    end
  end

  class ExpressionNode < TemplateItemNode
    child :method, [CallNode]
    def to_s
      "{{#{method.join "."}}}"
    end
  end

  class BlockExpressionNode < ExpressionNode
    child :contents, TemplateNode
    child :closer, CallNode

    def name
      method.first.name
    end

    def to_s
      "{{##{method.join ""}}}#{contents}{{/#{closer.name}}}"
    end

    def inspect
      r = "{{##{method.join ""}}}\n"
      r << "  "
      r << contents.inspect.split("\n").join("\n  ")
      r
    end
  end

  class BlockExpressionNodeWithElse < BlockExpressionNode
    child :alternate, TemplateNode

    def to_s
      "{{##{method.join ""}}}#{contents}{{else}}#{alternate}{{/#{closer.name}}}"
    end

    def inspect
      r = "{{##{method.join ""}}}\n"
      r << contents.inspect.split("\n").join("\n  ")
      r << "\n  {{else}}\n"
      r << alternate.inspect.split("\n").join("\n  ")
      r
    end
  end

  class SafeExpressionNode < ExpressionNode
    def to_s
      "{{{#{method.join "."}}}}"
    end
  end

  class CommentNode < TemplateItemNode
    value :comment, String
    def to_s
      "{{! #{comment.strip}}}"
    end
  end

  class PartialNode < TemplateItemNode
    value :name, String
    child :context_call, [CallNode]
    child :context_value, ValueNode

    def context
      context_call.any? ? context_call : context_value
    end

    def to_s
      "{{>#{name}}}"
    end
  end
end
