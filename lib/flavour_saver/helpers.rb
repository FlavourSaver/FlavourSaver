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
          @locals[name]
        else 
          @source.send(name, *args, &b)
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

