require 'flavour_saver'

describe FlavourSaver::Runtime do
  let(:template) { '' }
  let(:tokens)   { FlavourSaver.lex(template) }
  let(:ast)      { FlavourSaver.parse(tokens) }
  let(:context)  { double(:context) }
  subject        { FlavourSaver::Runtime.new(ast, context) }

  describe '#evaluate_node' do
    describe 'when passed a TemplateNode' do
      let(:template) { "hello world" }

      it "concatenates all the nodes items together" do
        expect(subject.evaluate_node(ast)).to eq 'hello world'
      end
    end

    describe 'when passed an OutputNode' do
      let(:template) { "hello world" }

      it "returns the value of OutputNodes" do
        node = ast.items.first
        expect(subject.evaluate_node(node)).to eq 'hello world'
      end
    end

    describe 'when passed a StringNode' do
      let(:template) { "{{foo \"WAT\"}}" }
      let(:node)     { ast.items.select { |n| n.class == FlavourSaver::ExpressionNode }.first.method.first.arguments.first }

      it 'returns the value of the string' do
        expect(subject.evaluate_node(node)).to eq 'WAT'
      end
    end

    describe 'when passed an ExpressionNode' do
      let(:node)      { ast.items.select { |n| n.class == FlavourSaver::ExpressionNode }.first }
      let (:template) { "{{foo}}" }

      it 'calls evaluate_node with the node' do
        expect(subject).to receive(:evaluate_expression).with(node)
        subject.evaluate_node(node)
      end

      it 'should HTML escape the output' do
        expect(context).to receive(:foo).and_return("<html>LOL</html>")
        expect(subject.evaluate_node(node)).to eq '&lt;html&gt;LOL&lt;/html&gt;'
      end
    end

    describe 'when passed a SafeExpressionNode' do
      let(:node)      { ast.items.select { |n| n.class == FlavourSaver::SafeExpressionNode }.first }
      let (:template) { "{{{foo}}}" }

      it 'should not HTML escape the output' do
        expect(context).to receive(:foo).and_return("<html>LOL</html>")
        expect(subject.evaluate_node(node)).to eq '<html>LOL</html>'
      end
    end

    describe 'when passed a CommentNode' do
      let(:template) { "{{! I am a comment}}" }
      let(:node)     { ast.items.select { |n| n.class == FlavourSaver::CommentNode }.first }

      it 'should return zilch' do
        expect(subject.evaluate_node(node)).to eq ''
      end
    end

    describe 'when passed a BlockExpressionStartNode' do
      let(:template) { "{{#foo}}bar{{/foo}}baz" }

      it 'snatches up the block contents and skips them from evaluation' do
        allow(context).to receive(:foo)
        expect(subject.evaluate_node(ast)).to eq 'baz'
      end
    end
  end

  describe '#evaluate_expression' do
    let(:node) { ast.items.select { |n| n.class == FlavourSaver::ExpressionNode }.first }
    let(:expr) { node }

    describe 'when called with a simple method expression' do
      let (:template) { "{{foo}}" }

      it 'calls the method and return the result' do
        expect(context).to receive(:foo).and_return('foo result')
        expect(subject.evaluate_expression(expr)).to eq 'foo result'
      end
    end

    describe 'when called with a simple method with arguments' do
      let(:template) { "{{hello \"world\"}}" }

      it 'calls the method with the arguments and return the result' do
        expect(context).to receive(:hello).with("world").and_return("hello world")
        expect(subject.evaluate_expression(expr)).to eq 'hello world'
      end
    end

    describe 'when called with a simple method with another simple method argument' do
      let(:template) { "{{hello world}}" }

      it 'calls hello & world on the context and return the result' do
        expect(context).to receive(:world).and_return('world')
        expect(context).to receive(:hello).with('world').and_return('hello world')
        expect(subject.evaluate_expression(expr)).to eq 'hello world'
      end
    end

    describe 'when called with a subexpression' do
      let(:template) { "{{hello (there world)}}" }

      it 'calls there & world first, then passes off to hello' do
        expect(context).to receive(:world).and_return('world')
        expect(context).to receive(:there).with('world').and_return('there world')
        expect(context).to receive(:hello).with('there world').and_return('hello there world')
        expect(subject.evaluate_expression(expr)).to eq 'hello there world'
      end
    end

    describe 'when called with an object path' do
      let(:template) { "{{hello.world}}" }

      it 'calls world on the result of hello' do
        allow(context).to receive_message_chain(:hello, :world).and_return('hello world')
        expect(subject.evaluate_expression(expr)).to eq 'hello world'
      end
    end

    describe 'when called with a literal' do
      let(:template) { "{{[WAT]}}" }

      it 'indexes the context with WAT' do
        expect(context).to receive(:[]).with('WAT').and_return 'w00t'
        expect(subject.evaluate_expression(expr)).to eq 'w00t'
      end
    end

    describe 'when called with an object path containing a literal' do
      let (:template) { "{{hello.[WAT].world}}" }

      it 'indexes the result of hello and calls world on it' do
        world = double(:world)
        expect(world).to receive(:world).and_return('vr00m')
        hash = double(:hash)
        expect(hash).to receive(:[]).with('WAT').and_return(world)
        expect(context).to receive(:hello).and_return(hash)
        expect(subject.evaluate_expression(expr)).to eq 'vr00m'
      end
    end

    describe 'when called with an path containing array indexes' do
      let (:template) { "{{hello.[0].[1]}}" }

      it 'indexes the value of a nested array' do
        array2 = ['w00t', 'vr00m']
        array = [array2]
        expect(context).to receive(:hello).and_return(array)
        expect(subject.evaluate_expression(expr)).to eq 'vr00m'
      end

      it 'handles non-existent indexes' do
        world = ['w00t']
        array = [world]
        expect(context).to receive(:hello).and_return(array)
        expect(subject.evaluate_expression(expr)).to eq nil
      end

      it 'handles calling on nil values' do
        expect(context).to receive(:hello).and_return(nil)
        expect(subject.evaluate_expression(expr)).to eq nil
      end
    end

    describe 'when called with a parent call node without a surrounding block' do
      let (:template) { "{{../foo}}" }

      it 'raises an error' do
        expect { subject.evaluate_expression(expr) }.to raise_error(FlavourSaver::UnknownContextException)
      end
    end

    describe 'when called with a hash argument containing a string value' do
      let (:template) { '{{foo bar="baz"}}' }

      it 'receives the argument as a hash' do
        expect(context).to receive(:foo).with({:bar => 'baz'})
        subject.evaluate_expression(expr)
      end
    end

    describe 'when called with a hash argument containing a method reference' do
      let (:template) { "{{foo bar=baz}}" }

      it 'calls the value and returns it\'s result in the hash' do
        expect(context).to receive(:baz).and_return('OMGLOLWAT')
        expect(context).to receive(:foo).with({:bar => 'OMGLOLWAT'})
        subject.evaluate_expression(expr)
      end
    end

  end

  describe '#evaluate_block' do
    let(:template) { "{{#foo}}hello world{{/foo}}" }
    let(:block)    { ast.items.first }

    it 'creates a new runtime' do
      expect(subject).to receive(:create_child_runtime)
      allow(context).to receive(:foo)
      subject.evaluate_block(block, context)
    end
  end

  describe '#create_child_runtime' do
    it 'creates a new runtime' do
      expect(subject.create_child_runtime([])).to be_a(FlavourSaver::Runtime)
    end
  end

end
