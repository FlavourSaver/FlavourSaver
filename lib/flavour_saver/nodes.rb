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
      str = str.dup # RLTK magic?
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
    child :sibling, [BlockExpressionNode]

    def name
      method.first.name
    end
  end

  class BlockExpressionCloseNode < BlockExpressionNode 

    def opened_by=(node)
      self.sibling = [node]
      node
    end

    def opened_by
      sibling.first
    end

    def to_s
      "{{/#{name}##{object_id}}}"
    end
  end

  class BlockExpressionStartNode < BlockExpressionNode

    def closed_by=(node)
      self.sibling=[node]
      node
    end

    def closed_by
      sibling.first
    end

    def to_s
      "{{##{method.map(&:to_s).join ''}##{object_id}}}"
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
