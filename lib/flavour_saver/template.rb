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
      # Include standard helper methods
      scope.extend Helpers

      # Include local variables
      scope.extend Module.new do 
        locals.each do |k,v|
          define_method k.to_sym { v }
        end
      end

      Runtime.run(@ast,scope)
    end
  end

end
