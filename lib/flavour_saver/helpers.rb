require 'delegate'

module FlavourSaver
  module Helpers
    class Defaults
      def with(args)
        yield.contents args
      end

      def each(collection)
        collection.each do |element|
          yield.contents element
        end
      end

      def if(truthy)
        if truthy
          yield.contents
        else
          yield.inverse
        end
      end

      def unless(falsy,&b)
        self.if(!falsy,&b)
      end

      def this
        @source || self
      end
    end

    class Decorator < Defaults

      def initialize(locals, source)
        @locals = locals
        @source = source
      end

      def respond_to?(name)
        @locals.keys.member?(name) || @source.respond_to?(name)
      end

      def method_missing(name,*args,&b)
        if @locals[name]
          call_local(name, *args, &b)
        else 
          @source.send(name, *args, &b)
        end
      end

      private

      def call_local(name,*args,&b)
        if b
          call_local_with_block(name,*args,&b)
        elsif @locals[name].respond_to?(:call)
          @locals[name].call(*args)
        else
          @locals[name]
        end
      end

      def call_local_with_block(name, *args, &b) 
        block = BlockWrapper.new(b)
        local = @locals[name]
        result = if local.respond_to? :call
                   local.call(*args,&block)
                 else
                   local
                 end
        unless block.called?
          block_result = b.call
          if result && (block_result.respond_to? :contents)
            block_result.contents
          elsif block_result.respond_to? :inverse
            block_result.inverse
          else
            result
          end
        else
          result
        end
      end

      class BlockWrapper
        def initialize(block)
          @block = block
          @called = 0
        end

        def call(*args)
          @called += 1
          @block.call(*args)
        end

        def called
          @called
        end

        def called?
          @called > 0
        end
      end
    end

    module_function

    def registered_helpers
      @registered_helpers ||= {}
    end

    def register_helper(method,&b)
      if method.respond_to? :name
        registered_helpers[method.name.to_sym] = method
      elsif b
        registered_helpers[method.to_sym] = b
      end
    end

    def deregister_helper(*names)
      names.each do |name|
        registered_helpers.delete(name.to_sym)
      end
    end

    def reset_helpers
      @registered_helpers = {}
    end

    def decorate_with(context, helper_names=[], locals={})
      helpers = if helper_names.any?
                  helper_names = helper_names.map(&:to_sym)
                  registered_helpers.select { |k,v| helper_names.member? k }.merge(locals)
                else
                  helpers = registered_helpers
                end
      helpers.merge(locals)
      Decorator.new(helpers, context)
    end

  end
end

