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
          @locals[name].call(*args, &b)
        elsif @source.respond_to? name
          @source.send(name, *args, &b)
        end
      end
    end

    module_function

    def registered_helpers
      @registered_helpers ||= {}
    end

    def register_helper(name,&b)
      registered_helpers[name.to_sym] = b
    end

    def deregister_helper(*names)
      names.each do |name|
        registered_helpers.delete(name.to_sym)
      end
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

# module FlavourSaver
#   module Helpers
#     module Default
#       def with(argument) 
#         yield argument
#       end

#       def each(collection)
#         collection.each do |element|
#           yield element
#         end
#       end

#       def if(truthy)
#         yield if truthy
#       end

#       def unless(falsy, &b)
#         self.if(!falsy,&b)
#       end

#       def this
#         self
#       end
#     end

#     class Wrapper 
#       def initialize(source)
#         @source = source
#       end

#       def respond_to?(method)
#         super || @source.respond_to?(method)
#       end

#       def method_missing(method, *args)
#         @source.send(method,*args)
#       end
#     end

#     module_function

#     def all_helpers
#       (registered_helpers + [Default]).uniq
#     end

#     def decorate_with(scope,helpers,locals)
#       helpers = all_helpers unless helpers
#       locals  = {} unless locals

#       scope = decorate_with_helpers(scope, helpers)
#       decorate_with_locals(scope, locals)
#     end

#     def decorate_with_helpers(scope,helpers=all_helpers)
#       scope = if scope.is_a? Wrapper
#                 scope
#               else
#                 Wrapper.new(scope)
#               end
#       helpers.each do |helper|
#         scope.extend(helper) unless scope.is_a? helper
#       end
#       scope
#     end

#     def decorate_with_locals(scope,locals={})
#       scope = if scope.is_a? Wrapper
#                 scope
#               else
#                 Wrapper.new(scope)
#               end
#       local_mixin = Module.new
#       locals.each do |name,value| 
#         local_mixin.send(:define_method, name.to_sym) do
#           value
#         end
#       end
#       scope.extend local_mixin
#       scope
#     end

#     def register_helper(helper_module)
#       registered_helpers << helper_module
#     end

#     def deregister_helper(helper_module)
#       registered_helpers.delete(helper_module)
#     end

#     def registered_helpers
#       @registered_helpers ||= [Default]
#     end

#   end
# end
