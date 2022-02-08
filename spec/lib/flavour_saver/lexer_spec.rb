require 'flavour_saver/lexer'

describe FlavourSaver::Lexer do
  it 'is an RLTK lexer' do
    expect(subject).to be_a(RLTK::Lexer)
  end

  describe 'Tokens' do
    describe 'Expressions' do
      describe '{{foo}}' do
        subject { FlavourSaver::Lexer.lex "{{foo}}" }

        it 'begins with an EXPRST' do
          expect(subject.first.type).to eq :EXPRST
        end

        it 'ends with an EXPRE' do
          expect(subject[-2].type).to eq :EXPRE
        end

        it 'contains only the identifier "foo"' do
          expect(subject[1..-3].size).to eq 1
          expect(subject[1].type).to eq :IDENT
          expect(subject[1].value).to eq 'foo'
        end
      end

      describe '{{foo bar}}' do
        subject { FlavourSaver::Lexer.lex "{{foo bar}}" }

        it 'has tokens in the correct order' do
          expect(subject.map(&:type)).to eq [ :EXPRST, :IDENT, :WHITE, :IDENT, :EXPRE, :EOS ]
        end

        it 'has values in the correct order' do
          expect(subject.map(&:value).compact).to eq [ 'foo', 'bar' ]
        end
      end

      describe '{{foo "bar"}}' do
        subject { FlavourSaver::Lexer.lex "{{foo \"bar\"}}" }

        it 'has tokens in the correct order' do
          expect(subject.map(&:type)).to eq [ :EXPRST, :IDENT, :WHITE, :STRING, :EXPRE, :EOS ]
        end

        it 'has values in the correct order' do
          expect(subject.map(&:value).compact).to eq [ 'foo', 'bar' ]
        end
      end

      describe '{{foo (bar "baz")}}' do
        subject { FlavourSaver::Lexer.lex "{{foo (bar 'baz')}}" }

        it 'has tokens in the correct order' do
          expect(subject.map(&:type)).to eq  [ :EXPRST, :IDENT, :WHITE, :OPAR, :IDENT, :WHITE, :S_STRING, :CPAR, :EXPRE, :EOS ]
        end

        it 'has values in the correct order' do
          expect(subject.map(&:value).compact).to eq [ 'foo', 'bar', 'baz' ]
        end
      end

      describe '{{foo bar="baz" hello="goodbye"}}' do
        subject { FlavourSaver::Lexer.lex '{{foo bar="baz" hello="goodbye"}}' }

        it 'has tokens in the correct order' do
          expect(subject.map(&:type)).to eq [ :EXPRST, :IDENT, :WHITE, :IDENT, :EQ, :STRING, :WHITE, :IDENT, :EQ, :STRING, :EXPRE, :EOS ]
        end

        it 'has values in the correct order' do
          expect(subject.map(&:value).compact).to eq [ 'foo', 'bar', 'baz', 'hello', 'goodbye' ]
        end
      end

      describe '{{0}}' do
        subject { FlavourSaver::Lexer.lex "{{0}}" }

        it 'properly lexes the expression' do
          expect(subject.map(&:type)).to eq(
            [:EXPRST, :NUMBER, :EXPRE, :EOS]
          )
        end

        it 'contains only the number "0"' do
          expect(subject[1..-3].size).to eq 1
          expect(subject[1].type).to eq :NUMBER
          expect(subject[1].value).to eq '0'
        end
      end

      describe '{{0.0123456789}}' do
        subject { FlavourSaver::Lexer.lex "{{0.0123456789}}" }

        it 'properly lexes the expression' do
          expect(subject.map(&:type)).to eq(
            [:EXPRST, :NUMBER, :EXPRE, :EOS]
          )
        end

        it 'contains only the number "0.0123456789"' do
          expect(subject[1..-3].size).to eq 1
          expect(subject[1].type).to eq :NUMBER
          expect(subject[1].value).to eq '0.0123456789'
        end
      end
    end

    describe 'Identities' do

      it 'supports as ruby methods' do
        ids = %w( _ __ __123__ __ABC__ ABC123 Abc134def )
        ids.each do |id|
          subject = FlavourSaver::Lexer.lex "{{#{id}}}"
          expect(subject[1].type).to eq :IDENT
          expect(subject[1].value).to eq id
        end
      end

      it 'maps non-ruby identities to literals' do
        ids = %w( A-B 12_Mine - :example 0A test? )
        ids.each do |id|
          subject = FlavourSaver::Lexer.lex "{{#{id}}}"
          expect(subject[1].type).to eq :LITERAL
          expect(subject[1].value).to eq id
        end
      end
    end

    describe '{{foo bar=(baz qux)}}' do
      subject { FlavourSaver::Lexer.lex '{{foo bar=(baz qux)}}' }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [:EXPRST, :IDENT, :WHITE, :IDENT, :EQ, :OPAR, :IDENT, :WHITE, :IDENT, :CPAR, :EXPRE, :EOS]
      end

      it 'has values in the correct order' do
        expect(subject.map(&:value).compact).to eq [ 'foo', 'bar', 'baz', 'qux' ]
      end
    end

    describe '{{else}}' do
      subject { FlavourSaver::Lexer.lex '{{else}}' }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [ :EXPRST, :ELSE, :EXPRE, :EOS ]
      end
    end

    describe 'Object path expressions' do
      describe '{{foo.bar}}' do
        subject { FlavourSaver::Lexer.lex "{{foo.bar}}" }

        it 'has tokens in the correct order' do
          expect(subject.map(&:type)).to eq [ :EXPRST, :IDENT, :DOT, :IDENT, :EXPRE, :EOS ]
        end

        it 'has the correct values' do
          expect(subject.map(&:value).compact).to eq ['foo', 'bar']
        end
      end

      describe '{{foo.[10].bar}}' do
        subject { FlavourSaver::Lexer.lex "{{foo.[10].bar}}" }

        it 'has tokens in the correct order' do
          expect(subject.map(&:type)).to eq [ :EXPRST, :IDENT, :DOT, :LITERAL, :DOT, :IDENT, :EXPRE, :EOS ]
        end

        it 'has the correct values' do
          expect(subject.map(&:value).compact).to eq ['foo', '10', 'bar']
        end
      end

      describe '{{foo.[he!@#$(&@klA)].bar}}' do
        subject { FlavourSaver::Lexer.lex '{{foo.[he!@#$(&@klA)].bar}}' }

        it 'has tokens in the correct order' do
          expect(subject.map(&:type)).to eq [ :EXPRST, :IDENT, :DOT, :LITERAL, :DOT, :IDENT, :EXPRE, :EOS ]
        end

        it 'has the correct values' do
          expect(subject.map(&:value).compact).to eq ['foo', 'he!@#$(&@klA)', 'bar']
        end
      end
    end

    describe 'Triple-stash expressions' do
      subject { FlavourSaver::Lexer.lex "{{{foo}}}" }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [ :TEXPRST, :IDENT, :TEXPRE, :EOS ]
      end
    end

    describe 'Comment expressions' do
      subject { FlavourSaver::Lexer.lex "{{! WAT}}" }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [ :EXPRST, :BANG, :COMMENT, :EXPRE, :EOS ]
      end
    end

    describe 'Backtrack expression' do
      subject { FlavourSaver::Lexer.lex "{{../foo}}" }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [:EXPRST, :DOT, :DOT, :FWSL, :IDENT, :EXPRE, :EOS]
      end
    end

    describe 'Carriage-return and new-lines' do
      subject { FlavourSaver::Lexer.lex "{{foo}}\n{{bar}}\r{{baz}}" }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [:EXPRST,:IDENT,:EXPRE,:OUT,:EXPRST,:IDENT,:EXPRE,:OUT,:EXPRST,:IDENT,:EXPRE,:EOS]
      end
    end

    describe 'Block Expressions' do
      subject { FlavourSaver::Lexer.lex "{{#foo}}{{bar}}{{/foo}}" }

      describe '{{#foo}}{{bar}}{{/foo}}' do
        it 'has tokens in the correct order' do
          expect(subject.map(&:type)).to eq [
            :EXPRST, :HASH, :IDENT, :EXPRE,
            :EXPRST, :IDENT, :EXPRE,
            :EXPRST, :FWSL, :IDENT, :EXPRE,
            :EOS
          ]
        end

        it 'has identifiers in the correct order' do
          expect(subject.map(&:value).compact).to eq [ 'foo', 'bar', 'foo' ]
        end
      end
    end

    describe 'Carriage return' do
      subject { FlavourSaver::Lexer.lex "\r" }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [:OUT,:EOS]
      end
    end

    describe 'New line' do
      subject { FlavourSaver::Lexer.lex "\n" }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [:OUT,:EOS]
      end
    end

    describe 'Single curly bracket' do
      subject { FlavourSaver::Lexer.lex "{" }

      it 'has tokens in the correct order' do
        expect(subject.map(&:type)).to eq [:OUT,:EOS]
      end
    end
  end
end
