require 'tilt/template'

module FlavourSaver
  class Template < Tilt::Template

    def self.engine_initialized?
      true
    end

    def prepare
      @ast = Parser.parse(Lexer.lex(data))
    end

    def evaluate(scope=Object.new,locals={},&block)
      Runtime.run(@ast,scope,locals)
    end
  end

end
