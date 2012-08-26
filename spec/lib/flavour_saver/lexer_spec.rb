require 'flavour_saver/lexer'

describe FlavourSaver::Lexer do
  it 'is an RLTK lexer' do
    subject.should be_a(RLTK::Lexer)
  end

  describe 'Tokens' do
    describe 'Expressions' do
      describe '{{foo}}' do
        subject { FlavourSaver::Lexer.lex "{{foo}}" }

        it 'begins with an EXPRESSION_START' do
          subject.first.type.should == :EXPRESSION_START
        end

        it 'ends with an EXPRESSION_END' do
          subject[-2].type.should == :EXPRESSION_END
        end

        it 'contains only the identifier "foo"' do
          subject[1..-3].size.should == 1
          subject[1].type.should == :IDENTIFIER
          subject[1].value.should == 'foo'
        end
      end

      describe '{{foo bar}}' do
        subject { FlavourSaver::Lexer.lex "{{foo bar}}" }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRESSION_START, :IDENTIFIER, :WHITESPACE, :IDENTIFIER, :EXPRESSION_END, :EOS ]
        end

        it 'has values in the correct order' do
          subject.map(&:value).compact.should == [ 'foo', 'bar' ]
        end
      end

      describe '{{foo "bar"}}' do
        subject { FlavourSaver::Lexer.lex "{{foo \"bar\"}}" }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRESSION_START, :IDENTIFIER, :WHITESPACE, :STRING, :EXPRESSION_END, :EOS ]
        end

        it 'has values in the correct order' do
          subject.map(&:value).compact.should == [ 'foo', 'bar' ]
        end
      end

      describe '{{foo bar="baz" hello="goodbye"}}' do
        subject { FlavourSaver::Lexer.lex '{{foo bar="baz" hello="goodbye"}}' }

        it 'has tokens in the correct order' do
          subject.map(&:type).should == [ :EXPRESSION_START, :IDENTIFIER, :WHITESPACE, :IDENTIFIER, :ASSIGN, :STRING, :WHITESPACE, :IDENTIFIER, :ASSIGN, :STRING, :EXPRESSION_END, :EOS ]
        end

        it 'has values in the correct order' do
          subject.map(&:value).compact.should == [ 'foo', 'bar', 'baz', 'hello', 'goodbye' ]
        end

      end
    end

    describe 'Object path expressions' do
      subject { FlavourSaver::Lexer.lex "{{foo.bar}}" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [ :EXPRESSION_START, :IDENTIFIER, :DOT, :IDENTIFIER, :EXPRESSION_END, :EOS ]
      end

      it 'has the correct values' do
        subject.map(&:value).compact.should == ['foo', 'bar']
      end
    end

    describe 'Triple-stash expressions' do
      subject { FlavourSaver::Lexer.lex "{{{foo}}}" }

      it 'has tokens in the correct order' do
        subject.map(&:type).should == [ :TRIPPLE_EXPRESSION_START, :IDENTIFIER, :TRIPPLE_EXPRESSION_END, :EOS ]
      end
    end

    describe 'Block Expressions' do
      subject { FlavourSaver::Lexer.lex "{{#foo}}{{bar}}{{/foo}}" }

      describe '{{#foo}}{{bar}}{{/foo}}' do
        it 'has tokens in the correct order' do
          subject.map(&:type).should == [
            :EXPRESSION_START, :BLOCK_START, :IDENTIFIER, :EXPRESSION_END, 
            :EXPRESSION_START, :IDENTIFIER, :EXPRESSION_END,
            :EXPRESSION_START, :BLOCK_END, :IDENTIFIER, :EXPRESSION_END,
            :EOS
          ]
        end

        it 'has identifiers in the correct order' do
          subject.map(&:value).compact.should == [ 'foo', 'bar', 'foo' ]
        end
      end

    end
  end
end
