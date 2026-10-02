require "flavour_saver/error"
require "flavour_saver/nodes"

module FlavourSaver
  # Recursive descent parser for the token stream produced by Lexer.
  #
  #   template      := (OUT | raw_block | expression)*
  #   raw_block     := RAWSTART RAWSTRING RAWEND
  #   expression    := block | expr | comment | safe_expr | partial
  #   block         := block_start template [else template] block_end
  #   block_start   := EXPRST (HASH | HAT) WHITE? IDENT [WHITE arguments] WHITE? EXPRE
  #   else          := EXPRST WHITE? (ELSE | HAT) WHITE? EXPRE
  #   block_end     := EXPRST FWSL WHITE? IDENT WHITE? EXPRE
  #   expr          := EXPRST contents EXPRE
  #   safe_expr     := TEXPRST contents TEXPRE | EXPRST AMP contents EXPRE
  #   comment       := EXPRST BANG COMMENT EXPRE
  #   partial       := EXPRST WHITE? GT WHITE? (STRING | (IDENT | LITERAL) [WHITE? (call | lit)]) WHITE? EXPRE
  #   contents      := WHITE? call WHITE?
  #   call          := DOT | object_path [WHITE arguments]
  #   arguments     := argument (WHITE argument)* [WHITE hash] | hash
  #   argument      := object_path | lit | OPAR contents CPAR
  #   hash          := IDENT EQ hash_value (WHITE IDENT EQ hash_value)*
  #   hash_value    := OPAR contents CPAR | string | NUMBER | object_path
  #   object_path   := object ((DOT | FWSL) (object | NUMBER))*
  #   object        := AT IDENT | IDENT | LITERAL | (DOT DOT FWSL)+ (IDENT | LITERAL)
  #   lit           := STRING | S_STRING | NUMBER | BOOL
  class Parser
    class UnbalancedBlockError < Error; end

    class NotInLanguage < Error
      def initialize(message = "String not in language.")
        super
      end
    end

    STRINGS = [:STRING, :S_STRING]
    LITERALS = [*STRINGS, :NUMBER, :BOOL]
    OBJECT_STARTS = [:AT, :IDENT, :LITERAL, :DOT]
    ARGUMENT_STARTS = [*OBJECT_STARTS, *LITERALS, :OPAR]

    def self.parse(tokens)
      new.parse(tokens)
    end

    def parse(tokens)
      @tokens = tokens
      @pos = 0
      template = parse_template
      expect(:EOS)
      raise NotInLanguage unless @pos == @tokens.size
      template
    end

    private

    def parse_template
      items = []
      loop do
        case peek
        when :OUT
          items << OutputNode.new(advance.value)
        when :RAWSTART
          items << parse_raw_block
        when :TEXPRST
          items << parse_triple_stash
        when :EXPRST
          break if else? || block_end?
          items << parse_expression
        else
          break
        end
      end
      TemplateNode.new(items)
    end

    def parse_raw_block
      expect(:RAWSTART)
      raw = expect(:RAWSTRING).value
      expect(:RAWEND)
      OutputNode.new(raw)
    end

    def parse_triple_stash
      expect(:TEXPRST)
      call = parse_contents
      expect(:TEXPRE)
      SafeExpressionNode.new(call)
    end

    def parse_expression
      case peek(1)
      when :HASH then parse_block
      when :HAT then parse_block
      when :BANG then parse_comment
      when :AMP
        expect(:EXPRST)
        expect(:AMP)
        call = parse_contents
        expect(:EXPRE)
        SafeExpressionNode.new(call)
      else
        if peek(skip_white(1)) == :GT
          parse_partial
        else
          expect(:EXPRST)
          call = parse_contents
          expect(:EXPRE)
          ExpressionNode.new(call)
        end
      end
    end

    def parse_block
      expect(:EXPRST)
      inverted = advance.type == :HAT
      skip(:WHITE)
      name = expect(:IDENT).value
      arguments = []
      if peek == :WHITE && peek(1) != :EXPRE
        advance
        arguments = parse_arguments
      end
      skip(:WHITE)
      expect(:EXPRE)
      opener = CallNode.new(name, arguments)

      contents = parse_template
      alternate = nil
      if else?
        parse_else
        alternate = parse_template
      end
      closer = parse_block_end(opener)

      if inverted
        # An inverted section renders its body when the value is falsy, so
        # the body is the alternate and the {{else}} part (if any) the contents.
        BlockExpressionNodeWithElse.new([opener], alternate || TemplateNode.new([]), closer, contents)
      elsif alternate
        BlockExpressionNodeWithElse.new([opener], contents, closer, alternate)
      else
        BlockExpressionNode.new([opener], contents, closer)
      end
    end

    def parse_else
      expect(:EXPRST)
      skip(:WHITE)
      raise NotInLanguage unless [:ELSE, :HAT].include?(peek)
      advance
      skip(:WHITE)
      expect(:EXPRE)
    end

    def parse_block_end(opener)
      expect(:EXPRST)
      expect(:FWSL)
      skip(:WHITE)
      name = expect(:IDENT).value
      skip(:WHITE)
      expect(:EXPRE)
      if name != opener.name
        raise UnbalancedBlockError, "Unable to find matching opening for {{/#{name}}}"
      end
      CallNode.new(name, [])
    end

    def parse_comment
      expect(:EXPRST)
      expect(:BANG)
      comment = expect(:COMMENT).value
      expect(:EXPRE)
      CommentNode.new(comment)
    end

    def parse_partial
      expect(:EXPRST)
      skip(:WHITE)
      expect(:GT)
      skip(:WHITE)
      if peek == :STRING
        name = advance.value
        skip(:WHITE)
        expect(:EXPRE)
        return PartialNode.new(name, [])
      end

      raise NotInLanguage unless [:IDENT, :LITERAL].include?(peek)
      name = advance.value
      skip(:WHITE)
      partial =
        if peek == :EXPRE
          PartialNode.new(name, [])
        elsif LITERALS.include?(peek)
          PartialNode.new(name, [], parse_literal)
        else
          PartialNode.new(name, parse_call, nil)
        end
      skip(:WHITE)
      expect(:EXPRE)
      partial
    end

    def parse_contents
      skip(:WHITE)
      call = parse_call
      skip(:WHITE)
      call
    end

    def parse_call
      if peek == :DOT && peek(1) != :DOT
        advance
        return [CallNode.new("this", [])]
      end

      path = parse_object_path
      if peek == :WHITE && ARGUMENT_STARTS.include?(peek(1))
        advance
        path.last.arguments = parse_arguments
      end
      path
    end

    def parse_arguments
      arguments = []
      loop do
        if hash_item?
          arguments << parse_hash
          break
        end
        arguments << parse_argument
        break unless peek == :WHITE && ARGUMENT_STARTS.include?(peek(1))
        advance
      end
      arguments
    end

    def parse_argument
      if peek == :OPAR
        parse_subexpression
      elsif LITERALS.include?(peek)
        parse_literal
      else
        parse_object_path
      end
    end

    def parse_subexpression
      expect(:OPAR)
      call = parse_contents
      expect(:CPAR)
      call
    end

    def parse_hash
      hash = {}
      loop do
        key = expect(:IDENT).value.to_sym
        expect(:EQ)
        hash[key] =
          case peek
          when :OPAR then parse_subexpression
          when *STRINGS then StringNode.new(advance.value)
          when :NUMBER then NumberNode.new(advance.value)
          else parse_object_path
          end
        break unless peek == :WHITE && hash_item?(1)
        advance
      end
      hash
    end

    def parse_literal
      token = advance
      case token.type
      when *STRINGS then StringNode.new(token.value)
      when :NUMBER then NumberNode.new(token.value)
      when :BOOL then token.value ? TrueNode.new(true) : FalseNode.new(false)
      else raise NotInLanguage
      end
    end

    def parse_object_path
      path = [parse_object]
      while [:DOT, :FWSL].include?(peek)
        advance
        # Accomodates objects dereferenced with a number like foo.0.text
        path << ((peek == :NUMBER) ? LiteralCallNode.new(advance.value, []) : parse_object)
      end
      path
    end

    def parse_object
      case peek
      when :AT
        advance
        LocalVarNode.new(expect(:IDENT).value)
      when :IDENT
        CallNode.new(advance.value, [])
      when :LITERAL
        LiteralCallNode.new(advance.value, [])
      when :DOT
        depth = 0
        while peek == :DOT
          expect(:DOT)
          expect(:DOT)
          expect(:FWSL)
          depth += 1
        end
        raise NotInLanguage unless [:IDENT, :LITERAL].include?(peek)
        ParentCallNode.new(advance.value, [], depth)
      else
        raise NotInLanguage
      end
    end

    # {{else}}, {{^}} or {{ ^ }}, but not the inverted section {{^foo}}.
    def else?
      return false unless peek == :EXPRST
      i = skip_white(1)
      case peek(i)
      when :ELSE then true
      when :HAT then i > 1 || peek(skip_white(i + 1)) != :IDENT
      else false
      end
    end

    def block_end?
      peek == :EXPRST && peek(1) == :FWSL
    end

    def hash_item?(offset = 0)
      peek(offset) == :IDENT && peek(offset + 1) == :EQ
    end

    def peek(offset = 0)
      token = @tokens[@pos + offset]
      token&.type
    end

    def skip_white(offset)
      (peek(offset) == :WHITE) ? offset + 1 : offset
    end

    def advance
      token = @tokens[@pos] or raise NotInLanguage
      @pos += 1
      token
    end

    def expect(type)
      raise NotInLanguage unless peek == type
      advance
    end

    def skip(type)
      advance if peek == type
    end
  end
end
