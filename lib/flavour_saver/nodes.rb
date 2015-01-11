require 'rltk'
require 'rltk/ast'
require 'flavour_saver/nodes'

module FlavourSaver
  class Node < RLTK::ASTNode
    def inspect
      to_s.inspect
    end
  end

  class TemplateItemNode < Node; end

  class TemplateNode < Node
    child :items, [TemplateItemNode]

    def to_s
      items.map(&:to_s).join ''
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

    def arguments_to_str(str='')
      str = str.dup # RLTK magic?
      arguments.each do |arg|
        str << ' '
        if arg.respond_to? :join
          str << arg.join('.')
        elsif arg.respond_to? :keys
          arg.each do |k,v|
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
    value :depth, Fixnum

    def to_callnode
      CallNode.new(name,arguments)
    end
    def to_s
      "#{'../' * depth}#{super}"
    end
  end

  class ExpressionNode < TemplateItemNode
    child :method, [CallNode]
    def to_s
      "{{#{method.map(&:to_s).join '.'}}}"
    end
  end

  class BlockExpressionNode < ExpressionNode
    child :contents, TemplateNode
    child :closer,   CallNode

    def name
      method.first.name
    end

    def to_s
      "{{##{method.map(&:to_s).join ''}}}#{contents.to_s}{{/#{closer.name}}}"
    end

    def inspect
      r = "{{##{method.map(&:to_s).join ''}}}\n"
      r << "  "
      r << contents.inspect.split("\n").join("\n  ")
      r
    end
  end

  class BlockExpressionNodeWithElse < BlockExpressionNode
    child :alternate, TemplateNode

    def to_s
      "{{##{method.map(&:to_s).join ''}}}#{contents.to_s}{{else}}#{alternate.to_s}{{/#{closer.name}}}"
    end

    def inspect
      r = "{{##{method.map(&:to_s).join ''}}}\n"
      r << contents.inspect.split("\n").join("\n  ")
      r << "\n  {{else}}\n"
      r << alternate.inspect.split("\n").join("\n  ")
      r
    end
  end

  class SafeExpressionNode < ExpressionNode
    def to_s
      "{{{#{method.map(&:to_s).join '.'}}}}"
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
