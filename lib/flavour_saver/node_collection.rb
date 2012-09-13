module FlavourSaver
  class NodeCollection
    include Enumerable

    def initialize(collection)
      @collection = collection
    end

    def each
      @collection.each do |node|
        yield node
      end
    end

    def toggle
      result = []
      target = result
      each do |node|
        if yield node
          if target == result
            target = []
            result << target
          else
            target = result
          end
        end
        target << node
      end
      result
    end

    def to_a
      @block = nil
      toggle do |node|
        puts "should I toggle for #{node.inspect}? "
        if !@block && node.respond_to?(:closed_by)
          puts "responds to :closed_by"
          puts "and is closed by #{node.closed_by.inspect}"
          @block = node.closed_by
          puts "block set to #{@block.inspect}"
          puts "toggling in"
          true
        end

        if @block && (node == @block)
          puts "toggling out"
          @block = nil
          true
        end
      end
    end

  end
end
