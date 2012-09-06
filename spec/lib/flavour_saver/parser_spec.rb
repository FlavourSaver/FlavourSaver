require 'flavour_saver/parser'
require 'flavour_saver/lexer'

describe FlavourSaver::Parser do
  it 'is a RLTK::Parser' do
    subject.should be_a(RLTK::Parser)
  end

  describe '{{foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo}}')) }

    it 'is an expression node' do
      subject.should == 'foo'
    end
  end

end
