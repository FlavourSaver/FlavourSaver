require 'cgi'

module FlavourSaver
  UnknownNodeTypeException          = Class.new(StandardError)
  UnknownContextException           = Class.new(StandardError)
  InappropriateUseOfElseException   = Class.new(StandardError)
  UndefinedPrivateVariableException = Class.new(StandardError)
  UnknownHelperException            = Class.new(RuntimeError)
  ForbiddenMethodException          = Class.new(UnknownHelperException)
  class Runtime

    attr_accessor :context, :parent, :ast, :privates

    def self.run(ast, context, locals={}, helpers=[])
      self.new(ast, context, locals, helpers).to_s
    end

    def initialize(ast, context=nil, locals={}, helpers=[],parent=nil)
      @ast = ast
      @locals = locals
      @helpers = helpers
      @context = context
      @parent = parent
      @privates = parent ? parent.privates.dup : { 'root' => context }
    end

    def to_s(tmp_context = nil,privates={})
      result = nil
      if tmp_context
        old_context = @context
        @context = tmp_context
        old_privates = @privates
        @privates = @privates.dup.merge(privates) if privates.any?
        result = evaluate_node(@ast)
        @privates = old_privates
        @context = old_context
      else
        result = evaluate_node(@ast).to_s.force_encoding(Encoding::default_external)
      end
      result
    end

    def private_variable_set(name,value)
      @privates[name.to_s] = value
    end

    def private_variable_get(name)
      begin
        @privates.fetch(name)
      rescue KeyError
        raise UndefinedPrivateVariableException, "private variable not found @#{name}"
      end
    end

    def strip(tmp_context = nil)
      self.to_s(tmp_context).gsub(/[\s]+/,' ').strip
    end

    def evaluate_node(node)
      case node
      when TemplateNode
        node.items.map { |n| evaluate_node(n) }.join('')
      when BlockExpressionNode
        evaluate_block(node).to_s
      when OutputNode
        node.value
      when NumberNode
        if node.value =~ /\./
          node.value.to_f
        else
          node.value.to_i
        end
      when ValueNode
        node.value
      when SafeExpressionNode
        evaluate_expression(node).to_s
      when ExpressionNode
        escape(evaluate_expression(node).to_s)
      when CallNode
        evaluate_call(node)
      when Hash
        node.each do |key,value|
          node[key] = evaluate_argument(value)
        end
        node
      when CommentNode
        ''
      when PartialNode
        evaluate_partial(node)
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

    def evaluate_partial(node)
      _context = context
      _context = evaluate_argument(node.context) if node.context
      if defined?(::Rails)
        context.send(:render, :partial => node.name, :object => _context)
      else
        partial = Partial.fetch(node.name)
        if partial.respond_to? :call
          partial.call(_context)
        else
          create_child_runtime(partial).to_s(_context)
        end
      end
    end

    def evaluate_call(call, context=self.context, &block)
      context = Helpers.decorate_with(context,@helpers,@locals) unless context.is_a? Helpers::Decorator
      case call
      when ParentCallNode
        depth = call.depth
        (2..depth).inject(parent) { |p| p.parent }.evaluate_call(call.to_callnode,&block)
      when LiteralCallNode
        result = context.send(:[], call.name)
        result = result.call(*call.arguments.map { |a| evaluate_argument(a) },&block) if result.respond_to? :call
        result
      when LocalVarNode
        result = private_variable_get(call.name)
      else
        if forbidden_method? context, call.name
          raise ForbiddenMethodException, "Refusing to call #{call.name.inspect} from a template: it isn't a helper, a local, or part of the template context's own API. Register a helper if you meant to expose it, or use #{"{{[#{call.name}]}}"} to read a data field of that name."
        end
        if call.parent.is_a? BlockExpressionNode and !context.respond_to? call.name
          raise UnknownHelperException, "Template context doesn't respond to method #{call.name.inspect}."
        end
        context.public_send(call.name, *call.arguments.map { |a| evaluate_argument(a) }, &block)
      end
    end

    def evaluate_argument(arg)
      if arg.is_a? Array
        evaluate_object_path(arg)
      else
        evaluate_node(arg)
      end
    end

    def evaluate_object_path(path, &block)
      path.inject(context) do |context,call|
        context = evaluate_call(call, context, &block)
      end
    end

    def evaluate_expression(node, &block)
      evaluate_object_path(node.method)
    end

    def evaluate_block(node,block_context=@context)
      call = node.method.first
      content_runtime = create_child_runtime(node.contents)
      alternate_runtime = create_child_runtime(node.alternate) if node.respond_to? :alternate
      block_runtime = BlockRuntime.new(block_context,content_runtime,alternate_runtime)

      result = evaluate_call(call, block_context) { block_runtime }

      # If the helper fails to call it's provided block then all
      # sorts of wacky default behaviour kicks in. I don't like it,
      # but that's the spec.
      if !block_runtime.rendered?

        # If the result is collectiony then act as an implicit
        # "each"
        if result && result.respond_to?(:each)
          if result.respond_to?(:size) && (result.size > 0)
            r = []
            # Not using #each_with_index because the object might
            # not actually be an Enumerable
            count = 0
            result.each do |e|
              r << block_runtime.contents(e, {'index' => count})
              count += 1
            end
            result = r.join('')
          else
            result = block_runtime.inverse
          end

        # Otherwise it behaves as an implicit "if"
        elsif result
          result = block_runtime.contents result
        else
          if block_runtime.has_inverse?
            result = block_runtime.inverse
          else
            result = ''
          end
        end
      end
      result
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
        @render_count = 0
      end

      def contents(context=@block_context,locals={})
        @render_count += 1
        @content_runtime.to_s(context,locals) if @content_runtime
      end

      def inverse(context=@block_context)
        @render_count += 1
        @alternate_runtime.to_s(context) if @alternate_runtime
      end

      def has_inverse?
        !!@alternate_runtime
      end

      def rendered?
        @render_count > 0 ? @render_count : false
      end

      def rendered!
        @render_count += 1
      end
    end

    private

    # True unless +name+ resolves to something the application deliberately
    # made available to templates.
    #
    # This is an allowlist of *owners* rather than a denylist of names, because
    # a name denylist cannot be made complete. Object's inherited API is the
    # obvious hazard (instance_eval, send, instance_exec), but it is not the
    # whole of it: ActiveSupport mixes Object#try in from its own module and it
    # forwards to public_send, and Decorator#method_missing is public and
    # forwards to the context. Neither appears in Object.instance_methods.
    #
    # Only two things are legitimately dispatchable on the decorator itself:
    # helpers and locals, which live on a module extended onto this runtime's
    # decorator and so are absent from Decorator.ancestors; and FlavourSaver's
    # own helpers, which Defaults owns. Everything else defined on the
    # decorator is either Object's ambient surface or the decorator's internal
    # plumbing, and neither is template surface.
    #
    # A name the decorator doesn't define at all raises NameError here, which
    # means it will be delegated to the context object by method_missing --
    # ordinary template dispatch, and allowed.
    #
    # Only *publicly* reachable names are refused. #method resolves private
    # methods too, and refusing those as well would break every context method
    # sharing a name with a private Kernel method -- format, open, select,
    # print, test, load and some sixty others, all of which dispatch fine
    # today. They aren't reachable through public_send in any case: they fall
    # through to method_missing, which is guarded by its own use of
    # public_send.
    def forbidden_method?(context, name)
      owner = begin
                context.method(name).owner
              rescue NameError
                return false
              end

      return false if owner.equal? Helpers::Defaults
      return false unless Helpers::Decorator.ancestors.include? owner

      begin
        context.singleton_class.public_method_defined? name
      rescue TypeError
        # Integer, Symbol and Float have no singleton class. A primitive can't
        # carry a singleton method, so a name that resolved on one is
        # necessarily inherited -- refuse it. Reached only if a primitive is
        # ever passed here undecorated; the decorator wrapping in evaluate_call
        # normally prevents that, but the predicate must be correct on its own.
        true
      end
    end

    def escape(output)
      if output.respond_to?(:html_safe) && output.html_safe?
        # If the string is already marked as html_safe then don't
        # escape it any further.
        output

      else
        output = CGI.escapeHTML(output)

        # We can't just use CGI.escapeHTML because Handlebars does extra
        # escaping for its JavaScript environment. Thems the breaks.
        output = output.gsub(/(['"`])/) do |match|
          case match
          when "'"
            "&#x27;"
          when '"'
            "&quot;"
          when '`'
            "&#x60;"
          end
        end

        # Mark it as already escaped if we're in Rails
        output.html_safe if output.respond_to? :html_safe

        output
      end
    end
  end
end
