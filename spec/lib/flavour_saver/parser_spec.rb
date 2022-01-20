require 'flavour_saver/parser'
require 'flavour_saver/lexer'

describe FlavourSaver::Parser do
  let (:items) { subject.items }

  it 'is a RLTK::Parser' do
    expect(subject).to be_a(RLTK::Parser)
  end

  describe 'HTML template' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('<html><h1>Hello world!</h1></html>')) }

    it 'is an output node' do
      expect(items.first).to be_a(FlavourSaver::OutputNode)
    end

    it 'has the correct contents' do
      expect(items.first.value).to eq '<html><h1>Hello world!</h1></html>'
    end
  end

  describe 'HTML template containing a handlebars expression' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('<html>{{foo}}</html>')) }

    it 'has template output either side of the expression' do
      expect(items.map(&:class)).to eq [FlavourSaver::OutputNode, FlavourSaver::ExpressionNode, FlavourSaver::OutputNode]
    end
  end

  describe '{{foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo}}')) }

    it 'contains an expression node' do
      expect(items.first).to be_a(FlavourSaver::ExpressionNode)
    end

    it 'calls the method "foo" with no arguments' do
      expect(items.first.method).to be_one
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments).to be_empty
    end
  end

  describe '{{foo.bar}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo.bar}}')) }

    it 'calls two methods' do
      expect(items.first.method.size).to eq 2
    end

    it 'calls the method "foo" with no arguments first' do
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments).to be_empty
    end

    it 'calls the method "bar" with no arguments second' do
      expect(items.first.method[1]).to be_a(FlavourSaver::CallNode)
      expect(items.first.method[1].name).to eq 'bar'
      expect(items.first.method[1].arguments).to be_empty
    end
  end

  describe '{{foo.[&@^$*].bar}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo.[&@^$*].bar}}')) }

    it 'calls three methods' do
      expect(items.first.method.size).to eq 3
    end

    it 'calls the method "foo" with no arguments first' do
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments).to be_empty
    end

    it 'calls the method "&@^$*" with no arguments second' do
      expect(items.first.method[1]).to be_a(FlavourSaver::CallNode)
      expect(items.first.method[1].name).to eq '&@^$*'
      expect(items.first.method[1].arguments).to be_empty
    end

    it 'calls the method "bar" with no arguments third' do
      expect(items.first.method[2]).to be_a(FlavourSaver::CallNode)
      expect(items.first.method[2].name).to eq 'bar'
      expect(items.first.method[2].arguments).to be_empty
    end
  end

  describe '{{foo bar}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar}}')) }

    it 'calls the method "foo" with a method argument of "bar"' do
      expect(items.first.method).to be_one
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments).to be_one
      expect(items.first.method.first.arguments.first.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.arguments.first.first.name).to eq 'bar'
    end
  end

  describe '{{foo "bar" }}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo "bar" }}')) }

    it 'calls the method "foo" with a string argument of "bar"' do
      expect(items.first.method).to be_one
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments).to be_one
      expect(items.first.method.first.arguments.first).to be_a(FlavourSaver::StringNode)
      expect(items.first.method.first.arguments.first.value).to eq 'bar'
    end
  end

  describe '{{foo     bar  "baz" }}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo    bar  "baz" }}')) }

    it 'calls the method "foo"' do
      expect(items.first.method).to be_one
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
    end

    describe 'with arguments' do
      subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo    bar  "baz" }}')).items.first.method.first.arguments }

      describe '[0]' do
        it 'is the method call "bar" with no arguments' do
          expect(subject.first.first).to be_a(FlavourSaver::CallNode)
          expect(subject.first.first.name).to eq 'bar'
        end
      end

      describe '[1]' do
        it 'is the string "baz"' do
          expect(subject[1]).to be_a(FlavourSaver::StringNode)
          expect(subject[1].value).to eq 'baz'
        end
      end
    end
  end

  describe '{{foo (bar "baz") }}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo (bar "baz") }}')) }

    it 'calls the method "foo"' do
      expect(items.first.method).to be_one
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
    end

    describe 'with arguments' do
      subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo (bar "baz") }}')).items.first.method.first.arguments }

      describe '[0]' do
        it 'is a subexpression' do
          expect(subject.first.first).to be_a(FlavourSaver::CallNode)
          expect(subject.first.first.name).to eq 'bar'
        end
      end

    end
  end

  describe '{{foo bar="baz"}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar="baz"}}')) }

    it 'calls the method "foo" with the hash {:bar => "baz"} as arguments' do
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments.first).to be_a(Hash)
      expect(items.first.method.first.arguments.first).to eq({ :bar => FlavourSaver::StringNode.new('baz') })
    end
  end

  describe '{{foo bar=(baz "qux")}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar=(baz "qux")}}')) }

    it 'calls the method "foo" with the hash {:bar => (baz "qux")} as arguments' do
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments.first).to be_a(Hash)
      expect(items.first.method.first.arguments.first[:bar].first).to be_a(FlavourSaver::CallNode)
    end
  end

  describe "{{foo bar=1}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{foo bar=1}}")) }

    it "doesn't throw a NotInLanguage exception" do
      expect { subject }.to_not raise_error
    end

    it 'calls the method "foo" with the hash {:bar => 1} as arguments' do
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments.first).to be_a(Hash)
      expect(items.first.method.first.arguments.first).to eq({ :bar => FlavourSaver::NumberNode.new('1') })
    end
  end

  describe '{{foo bar="baz" fred="wilma"}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar="baz" fred="wilma"}}')) }

    it 'calls the method "foo" with the hash {:bar => "baz", :fred => "wilma"} as arguments' do
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments.first).to be_a(Hash)
      expect(items.first.method.first.arguments.first).to eq({ :bar => FlavourSaver::StringNode.new('baz'), :fred => FlavourSaver::StringNode.new('wilma') })
    end
  end

  describe '{{foo bar="baz" fred "wilma"}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar="baz" fred "wilma"}}')) }

    it 'raises an exception' do
      expect { subject }.to raise_exception(RLTK::NotInLanguage)
    end
  end

  describe '{{{foo}}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{{foo}}}')) }

    it 'returns a safe expression node' do
      expect(items.first).to be_a(FlavourSaver::SafeExpressionNode)
    end
  end

  describe '{{../foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{../foo}}')) }

    it 'returns a parent call node' do
      expect(items.first.method.first).to be_a(FlavourSaver::ParentCallNode)
    end
  end

  describe '{{! comment}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{! comment}}')) }

    it 'returns a comment node' do
      expect(items.first).to be_a(FlavourSaver::CommentNode)
    end
  end

  describe '{{#foo}}hello{{/foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{#foo}}hello{{/foo}}')) }

    it 'has a block start and end' do
      expect(items.map(&:class)).to eq [ FlavourSaver::BlockExpressionNode ]
    end

    describe '#contents' do
      it 'contains a single output node' do
        expect(items.first.contents.items.size).to eq 1
        expect(items.first.contents.items.first).to be_a(FlavourSaver::OutputNode)
        expect(items.first.contents.items.first.value).to eq 'hello'
      end
    end
  end

  describe '{{/foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{/foo}}')) }

    it 'raises a syntax error' do
      expect { subject }.to raise_error(RLTK::NotInLanguage)
    end
  end

  describe '{{#foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{#foo}}')) }

    it 'raises a syntax error' do
      expect { subject }.to raise_error(RLTK::NotInLanguage)
    end
  end

  describe "{{foo}}\n" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{foo}}\n")) }

    it 'has a block start and end' do
      expect(items.map(&:class)).to eq [ FlavourSaver::ExpressionNode, FlavourSaver::OutputNode ]
    end
  end

  describe '{{#foo}}{{#bar}}{{/foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{#foo}}{{#bar}}{{/foo}}')) }

    it 'raises a syntax error' do
      expect { subject }.to raise_error(FlavourSaver::Parser::UnbalancedBlockError)
    end
  end

  describe "{{#foo}}\n{{/foo}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{#foo}}\n{{/foo}}")) }

    it "doesn't throw a NotInLanguage exception" do
      expect { subject }.to_not raise_error
    end
  end

  describe "{{#foo}}{#foo}}{{/foo}}{{/foo}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{#foo}}{{#foo}}{{/foo}}{{/foo}}')) }

    describe 'the outer block' do
      let(:block) { subject.items.first }

      it 'should contain another block' do
        expect(block.contents.items.size).to eq 1
        expect(block.contents.items.first).to be_a(FlavourSaver::BlockExpressionNode)
      end
    end
  end

  describe "{{#foo bar 'baz'}}{{/foo}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{#foo bar 'baz'}}{{/foo}}")) }

    it "doesn't throw a NotInLanguage exception" do
      expect { subject }.to_not raise_error
    end
  end

  describe "{{#foo bar 'baz' }}{{/foo}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{#foo bar 'baz' }}{{/foo}}")) }

    it "doesn't throw a NotInLanguage exception" do
      expect { subject }.to_not raise_error
    end
  end
  describe '' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('')) }

    it 'returns an empty template' do
      expect(items).to be_empty
    end
  end
  describe '{{foo "bar" fred="wilma"}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo "bar" fred="wilma"}}')) }
    it 'calls the method "foo" with the "bar" and {:fred => "wilma"} as arguments' do
      expect(items.first.method.first).to be_a(FlavourSaver::CallNode)
      expect(items.first.method.first.name).to eq 'foo'
      expect(items.first.method.first.arguments.first).to be_a(FlavourSaver::StringNode)
      expect(items.first.method.first.arguments.first.value).to eq 'bar'
      expect(items.first.method.first.arguments.last).to be_a(Hash)
      expect(items.first.method.first.arguments.last).to eq({ :fred => FlavourSaver::StringNode.new('wilma') })
    end
  end
end
