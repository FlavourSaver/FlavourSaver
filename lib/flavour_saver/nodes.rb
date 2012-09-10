require 'rltk'
require 'rltk/ast'
require 'flavour_saver/nodes'

module FlavourSaver
  Node       = Class.new(RLTK::ASTNode)
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

  class StringNode < Node
    value :value, String

    def to_s
      value.inspect
    end
  end

  class CallNode < Node
    value :name, String
    value :arguments, Array

    def arguments_to_str(str='')
      arguments.each do |arg|
        str << ' '
        if arg.respond_to? :join
          str << arg.join('.')
        else
          str << arg
        end
      end
      str
    end

    def to_s
      arguments_to_str(name)
    end
  end

  class LiteralCallNode < CallNode
    def to_s
      arguments_to_str("[#{name.inspect}]")
    end
  end

  class ParentCallNode < CallNode
    def to_callnode
      CallNode.new(name,arguments)
    end
    def to_s
      "../#{super}"
    end
  end

  class InverseNode < TemplateItemNode ; end

  class ExpressionNode < TemplateItemNode
    child :method, [CallNode]
    def to_s
      "{{#{method.map(&:to_s).join '.'}}}"
    end
  end

  class BlockExpressionNode < ExpressionNode
    def name
      method.first.name
    end
  end

  class BlockCloseExpressionNode < BlockExpressionNode 
    def to_s
      "{{/#{name}}}"
    end
  end

  class BlockStartExpressionNode < BlockExpressionNode
    child :stop, [BlockCloseExpressionNode]
    def closed_by(node=nil)
      self.stop = [node] if node
      stop.first
    end

    def to_s
      "{{##{method.map(&:to_s).join '.'}}}"
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
end
