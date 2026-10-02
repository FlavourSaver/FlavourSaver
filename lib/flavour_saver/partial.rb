module FlavourSaver
  UnknownPartialException = Class.new(StandardError)

  class Partial
    def self.register_partial(name, content = nil, &block)
      partials[name.to_s] = if block.respond_to? :call
        block
      else
        Parser.parse(Lexer.lex(content))
      end
    end

    def self.reset_partials
      @partials = {}
    end

    def self.partials
      @partials ||= {}
    end

    def self.fetch(name)
      p = partials[name.to_s]
      raise UnknownPartialException, "I can't find the partial named #{name.inspect}" unless p
      p
    end
  end
end
