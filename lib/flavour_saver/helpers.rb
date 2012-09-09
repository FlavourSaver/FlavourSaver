module FlavourSaver
  module Helpers

    def with(argument) 
      puts "#with received argument #{argument.inspect}"
      yield argument
    end

    def each(collection)
      collection.each do |element|
        yield element
      end
    end

    def if(truthy)
      yield if truthy
    end

    def unless(falsy, &block)
      self.if(!falsy,&block)
    end
  end
end
