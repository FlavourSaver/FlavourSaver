module FlavourSaver
  module Helpers

    def with(argument) 
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

    def this
      self
    end
  end
end
