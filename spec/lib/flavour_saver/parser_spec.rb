require 'flavour_saver/parser'
require 'flavour_saver/lexer'

describe FlavourSaver::Parser do
  it 'is a RLTK::Parser' do
    subject.should be_a(RLTK::Parser)
  end

  describe 'HTML template' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('<html><h1>Hello world!</h1></html>')) }
    
    it 'is an output node' do
      subject.first.should be_a(FlavourSaver::OutputNode)
    end

    it 'has the correct contents' do
      subject.first.value.should == '<html><h1>Hello world!</h1></html>'
    end
  end

  describe 'HTML template containing a handlebars expression' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('<html>{{foo}}</html>')) }

    it 'has a template output either side of the expression' do
      subject.map(&:class).should == [FlavourSaver::OutputNode, FlavourSaver::ExpressionNode, FlavourSaver::OutputNode]
    end
  end

  describe '{{foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo}}')) }

    it 'is an expression node' do
      subject.first.should be_an(FlavourSaver::ExpressionNode)
    end
  end

  describe '{{foo.bar}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo.bar}}')) }

    it 'is an expression node' do
      subject.first.should be_an(FlavourSaver::ExpressionNode)
    end
  end
end
