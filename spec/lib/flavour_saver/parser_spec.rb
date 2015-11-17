require 'flavour_saver/parser'
require 'flavour_saver/lexer'

describe FlavourSaver::Parser do
  let (:items) { subject.items }

  it 'is a RLTK::Parser' do
    subject.should be_a(RLTK::Parser)
  end

  describe 'HTML template' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('<html><h1>Hello world!</h1></html>')) }

    it 'is an output node' do
      items.first.should be_a(FlavourSaver::OutputNode)
    end

    it 'has the correct contents' do
      items.first.value.should == '<html><h1>Hello world!</h1></html>'
    end
  end

  describe 'HTML template containing a handlebars expression' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('<html>{{foo}}</html>')) }

    it 'has template output either side of the expression' do
      items.map(&:class).should == [FlavourSaver::OutputNode, FlavourSaver::ExpressionNode, FlavourSaver::OutputNode]
    end
  end

  describe '{{foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo}}')) }

    it 'contains an expression node' do
      items.first.should be_an(FlavourSaver::ExpressionNode)
    end

    it 'calls the method "foo" with no arguments' do
      items.first.method.should be_one
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.should be_empty
    end
  end

  describe '{{foo.bar}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo.bar}}')) }

    it 'calls two methods' do
      items.first.method.size.should == 2
    end

    it 'calls the method "foo" with no arguments first' do
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.should be_empty
    end

    it 'calls the method "bar" with no arguments second' do
      items.first.method[1].should be_a(FlavourSaver::CallNode)
      items.first.method[1].name.should == 'bar'
      items.first.method[1].arguments.should be_empty
    end
  end

  describe '{{foo.[&@^$*].bar}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo.[&@^$*].bar}}')) }

    it 'calls three methods' do
      items.first.method.size.should == 3
    end

    it 'calls the method "foo" with no arguments first' do
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.should be_empty
    end

    it 'calls the method "&@^$*" with no arguments second' do
      items.first.method[1].should be_a(FlavourSaver::CallNode)
      items.first.method[1].name.should == '&@^$*'
      items.first.method[1].arguments.should be_empty
    end

    it 'calls the method "bar" with no arguments third' do
      items.first.method[2].should be_a(FlavourSaver::CallNode)
      items.first.method[2].name.should == 'bar'
      items.first.method[2].arguments.should be_empty
    end
  end

  describe '{{foo bar}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar}}')) }

    it 'calls the method "foo" with a method argument of "bar"' do
      items.first.method.should be_one
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.should be_one
      items.first.method.first.arguments.first.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.arguments.first.first.name.should == 'bar'
    end
  end

  describe '{{foo "bar" }}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo "bar" }}')) }

    it 'calls the method "foo" with a string argument of "bar"' do
      items.first.method.should be_one
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.should be_one
      items.first.method.first.arguments.first.should be_a(FlavourSaver::StringNode)
      items.first.method.first.arguments.first.value.should == 'bar'
    end
  end

  describe '{{foo     bar  "baz" }}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo    bar  "baz" }}')) }

    it 'calls the method "foo"' do
      items.first.method.should be_one
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
    end

    describe 'with arguments' do
      subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo    bar  "baz" }}')).items.first.method.first.arguments }

      describe '[0]' do
        it 'is the method call "bar" with no arguments' do
          subject.first.first.should be_a(FlavourSaver::CallNode)
          subject.first.first.name.should == 'bar'
        end
      end

      describe '[1]' do
        it 'is the string "baz"' do
          subject[1].should be_a(FlavourSaver::StringNode)
          subject[1].value.should == 'baz'
        end
      end
    end
  end

  describe '{{foo (bar "baz") }}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo (bar "baz") }}')) }

    it 'calls the method "foo"' do
      items.first.method.should be_one
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
    end

    describe 'with arguments' do
      subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo (bar "baz") }}')).items.first.method.first.arguments }

      describe '[0]' do
        it 'is a subexpression' do
          subject.first.first.should be_a(FlavourSaver::CallNode)
          subject.first.first.name.should == 'bar'
        end
      end

    end
  end

  describe '{{foo bar="baz"}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar="baz"}}')) }

    it 'calls the method "foo" with the hash {:bar => "baz"} as arguments' do
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.first.should be_a(Hash)
      items.first.method.first.arguments.first.should == { :bar => FlavourSaver::StringNode.new('baz') }
    end
  end

  describe '{{foo bar=(baz "qux")}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar=(baz "qux")}}')) }

    it 'calls the method "foo" with the hash {:bar => (baz "qux")} as arguments' do
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.first.should be_a(Hash)
      items.first.method.first.arguments.first[:bar].first.should be_a(FlavourSaver::CallNode)
    end
  end

  describe "{{foo bar=1}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{foo bar=1}}")) }

    it "doesn't throw a NotInLanguage exception" do
      -> { subject }.should_not raise_error
    end

    it 'calls the method "foo" with the hash {:bar => 1} as arguments' do
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.first.should be_a(Hash)
      items.first.method.first.arguments.first.should == { :bar => FlavourSaver::NumberNode.new('1') }
    end
  end

  describe '{{foo bar="baz" fred="wilma"}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar="baz" fred="wilma"}}')) }

    it 'calls the method "foo" with the hash {:bar => "baz", :fred => "wilma"} as arguments' do
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.first.should be_a(Hash)
      items.first.method.first.arguments.first.should == { :bar => FlavourSaver::StringNode.new('baz'), :fred => FlavourSaver::StringNode.new('wilma') }
    end
  end

  describe '{{foo bar="baz" fred "wilma"}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo bar="baz" fred "wilma"}}')) }

    it 'raises an exception' do
      -> { subject }.should raise_exception(RLTK::NotInLanguage)
    end
  end

  describe '{{{foo}}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{{foo}}}')) }

    it 'returns a safe expression node' do
      items.first.should be_a(FlavourSaver::SafeExpressionNode)
    end
  end

  describe '{{../foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{../foo}}')) }

    it 'returns a parent call node' do
      items.first.method.first.should be_a(FlavourSaver::ParentCallNode)
    end
  end

  describe '{{! comment}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{! comment}}')) }

    it 'returns a comment node' do
      items.first.should be_a(FlavourSaver::CommentNode)
    end
  end

  describe '{{#foo}}hello{{/foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{#foo}}hello{{/foo}}')) }

    it 'has a block start and end' do
      items.map(&:class).should == [ FlavourSaver::BlockExpressionNode ]
    end

    describe '#contents' do
      it 'contains a single output node' do
        items.first.contents.items.size.should == 1
        items.first.contents.items.first.should be_a(FlavourSaver::OutputNode)
        items.first.contents.items.first.value.should == 'hello'
      end
    end
  end

  describe '{{/foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{/foo}}')) }

    it 'raises a syntax error' do
      -> { subject }.should raise_error
    end
  end

  describe '{{#foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{#foo}}')) }

    it 'raises a syntax error' do
      -> { subject }.should raise_error
    end
  end

  describe "{{foo}}\n" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{foo}}\n")) }

    it 'has a block start and end' do
      items.map(&:class).should == [ FlavourSaver::ExpressionNode, FlavourSaver::OutputNode ]
    end
  end

  describe '{{#foo}}{{#bar}}{{/foo}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{#foo}}{{#bar}}{{/foo}}')) }

    it 'raises a syntax error' do
      -> { subject }.should raise_error
    end
  end

  describe "{{#foo}}\n{{/foo}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{#foo}}\n{{/foo}}")) }

    it "doesn't throw a NotInLanguage exception" do
      -> { subject }.should_not raise_error
    end
  end

  describe "{{#foo}}{#foo}}{{/foo}}{{/foo}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{#foo}}{{#foo}}{{/foo}}{{/foo}}')) }

    describe 'the outer block' do
      let(:block) { subject.items.first }

      it 'should contain another block' do
        block.contents.items.size.should == 1
        block.contents.items.first.should be_a(FlavourSaver::BlockExpressionNode)
      end
    end
  end

  describe "{{#foo bar 'baz'}}{{/foo}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{#foo bar 'baz'}}{{/foo}}")) }

    it "doesn't throw a NotInLanguage exception" do
      -> { subject }.should_not raise_error
    end
  end

  describe "{{#foo bar 'baz' }}{{/foo}}" do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex("{{#foo bar 'baz' }}{{/foo}}")) }

    it "doesn't throw a NotInLanguage exception" do
      -> { subject }.should_not raise_error
    end
  end
  describe '' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('')) }

    it 'returns an empty template' do
      items.should be_empty
    end
  end
  describe '{{foo "bar" fred="wilma"}}' do
    subject { FlavourSaver::Parser.parse(FlavourSaver::Lexer.lex('{{foo "bar" fred="wilma"}}')) }
    it 'calls the method "foo" with the "bar" and {:fred => "wilma"} as arguments' do
      items.first.method.first.should be_a(FlavourSaver::CallNode)
      items.first.method.first.name.should == 'foo'
      items.first.method.first.arguments.first.should be_a(FlavourSaver::StringNode)
      items.first.method.first.arguments.first.value.should == 'bar'
      items.first.method.first.arguments.last.should be_a(Hash)
      items.first.method.first.arguments.last.should == { :fred => FlavourSaver::StringNode.new('wilma') }
    end
  end
end
