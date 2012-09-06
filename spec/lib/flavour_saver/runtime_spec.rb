require 'flavour_saver'

describe FlavourSaver::Runtime do
  let(:tokens)   { FlavourSaver.lex(template) }
  let(:ast)      { FlavourSaver.parse(tokens) }
  let(:context)  { stub(:context) }
  subject        { FlavourSaver::Runtime.new(ast, context) }

  describe '#evaluate_node' do
    describe 'when passed a TemplateNode' do
      let(:template) { "hello world" }

      it "concatenates all the nodes items together" do
        subject.evaluate_node(ast).should == 'hello world'
      end
    end

    describe 'when passed an OutputNode' do
      let(:template) { "hello world" }

      it "returns the value of OutputNodes" do
        node = ast.items.first
        subject.evaluate_node(node).should == 'hello world'
      end
    end

    describe 'when passed a StringNode' do
      let(:template) { "{{foo \"WAT\"}}" }
      let(:node)     { ast.items.select { |n| n.class == FlavourSaver::ExpressionNode }.first.method.first.arguments.first }

      it 'returns the value of the string' do
        subject.evaluate_node(node).should == 'WAT'
      end
    end

    describe 'when passed an ExpressionNode' do
      let(:node)      { ast.items.select { |n| n.class == FlavourSaver::ExpressionNode }.first }
      let (:template) { "{{foo}}" }

      it 'calls evaluate_node with the node' do
        subject.should_receive(:evaluate_expression).with(node)
        subject.evaluate_node(node)
      end
    end
  end

  describe '#evaluate_expression' do
    let(:node) { ast.items.select { |n| n.class == FlavourSaver::ExpressionNode }.first }
    let(:expr) { node }

    describe 'when called with a simple method expression' do
      let (:template) { "{{foo}}" }

      it 'calls the method and return the result' do
        context.should_receive(:foo).and_return('foo result')
        subject.evaluate_expression(expr).should == 'foo result'
      end
    end

    describe 'when called with a simple method with arguments' do
      let(:template) { "{{hello \"world\"}}" }

      it 'calls the method with the arguments and return the result' do
        context.should_receive(:hello).with("world").and_return("hello world")
        subject.evaluate_expression(expr).should == 'hello world'
      end
    end

    describe 'when called with a simple method with another simple method argument' do
      let(:template) { "{{hello world}}" }

      it 'calls hello & world on the context and return the result' do
        context.should_receive(:world).and_return('world')
        context.should_receive(:hello).with('world').and_return('hello world')
        subject.evaluate_expression(expr).should == 'hello world'
      end
    end

    describe 'when called with an object path' do
      let(:template) { "{{hello.world}}" } 

      it 'calls world on the result of hello' do
        context.stub_chain(:hello, :world).and_return('hello world')
        subject.evaluate_expression(expr).should == 'hello world'
      end
    end

    describe 'when called with a literal' do
      let(:template) { "{{[WAT]}}" }

      it 'indexes the context with WAT' do
        context.should_receive(:[]).with('WAT').and_return 'w00t'
        subject.evaluate_expression(expr).should == 'w00t'
      end
    end

    describe 'when called with an object path containing a literal' do
      let (:template) { "{{hello.[WAT].world}}" } 
      
      it 'indexes the result of hello and calls world on it' do
        world = stub(:world)
        world.should_receive(:world).and_return('vr00m')
        hash = stub(:hash)
        hash.should_receive(:[]).with('WAT').and_return(world)
        context.should_receive(:hello).and_return(hash)
        subject.evaluate_expression(expr).should == 'vr00m'
      end
    end

    describe 'when called with a parent call node without a surrounding block' do
      let (:template) { "{{../foo}}" }

      it 'raises an error' do
        -> { subject.evaluate_expression(expr) }.should raise_error(FlavourSaver::UnknownContextException)
      end
    end
  end

  # describe 'hello world' do
  #   let(:template) { "hello world" }

  #   it 'returns "hello world"' do
  #     subject.should == "hello world"
  #   end
  # end
end
