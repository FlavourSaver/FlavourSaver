require 'flavour_saver/lexer'

describe FlavourSaver::Lexer do
  it 'is an RLTK lexer' do
    subject.should be_a(RLTK::Lexer)
  end

  describe 'Tokens' do
    describe 'Expressions' do
      describe '{{foo}}' do
        subject { FlavourSaver::Lexer.lex "{{foo}}" }

        it 'begins with an EXPRESSIONSTART' do
          subject.first.type.should == :EXPRESSIONSTART
        end

        it 'ends with an EXPRESSIONEND' do
          subject[-2].type.should == :EXPRESSIONEND
        end

        it 'contains only the identifier "foo"' do
          subject[1..-3].size.should == 1
          subject[1].type.should == :IDENTIFIER
          subject[1].value.should == 'foo'
        end
      end

    end
  end
end
