require 'flavour_saver/nodes'

describe FlavourSaver::Node do
  describe 'field inheritance' do
    let(:parent) { Class.new(FlavourSaver::Node) { value :name, String } }

    it 'gives a subclass the fields its parent had when the subclass was defined' do
      subclass = Class.new(parent)
      parent.value :depth, Integer

      expect(subclass.value_names).to eq [:name]
    end

    it "doesn't add a subclass's fields to its parent" do
      Class.new(parent) { value :depth, Integer }

      expect(parent.value_names).to eq [:name]
    end
  end

  describe 'field types' do
    let(:call) { FlavourSaver::CallNode.new('foo', []) }

    it 'accepts fields of the declared types' do
      expression = FlavourSaver::ExpressionNode.new([call])

      expect(expression.method).to eq [call]
      expect(call.parent).to eq expression
    end

    it 'accepts nil for a field typed with a class' do
      expect(FlavourSaver::PartialNode.new('foo', [], nil).context_value).to be_nil
    end

    it 'raises TypeMismatch for a value of the wrong class' do
      expect { FlavourSaver::CallNode.new(:foo, []) }
        .to raise_error(FlavourSaver::Node::TypeMismatch, 'FlavourSaver::CallNode#name must be String, not Symbol')
    end

    it 'raises TypeMismatch for a child of the wrong class' do
      expect { FlavourSaver::BlockExpressionNode.new([call], call) }
        .to raise_error(FlavourSaver::Node::TypeMismatch, /#contents must be FlavourSaver::TemplateNode, not FlavourSaver::CallNode/)
    end

    it 'raises TypeMismatch for an array containing the wrong class' do
      expect { FlavourSaver::ExpressionNode.new([call, FlavourSaver::StringNode.new('bar')]) }
        .to raise_error(FlavourSaver::Node::TypeMismatch, /#method must be \[FlavourSaver::CallNode\], not an Array of FlavourSaver::CallNode, FlavourSaver::StringNode/)
    end

    it 'raises TypeMismatch when an array field is not an array' do
      expect { FlavourSaver::ExpressionNode.new({ foo: call }) }
        .to raise_error(FlavourSaver::Node::TypeMismatch, /#method must be \[FlavourSaver::CallNode\], not Hash/)
      expect { FlavourSaver::ExpressionNode.new(nil) }.to raise_error(FlavourSaver::Node::TypeMismatch)
    end

    it 'checks fields set after the node is built' do
      expect { call.name = 1 }.to raise_error(FlavourSaver::Node::TypeMismatch)
    end

    it 'is a StandardError, as RLTK::TypeMismatch was' do
      expect(FlavourSaver::Node::TypeMismatch.superclass).to eq StandardError
    end
  end

  describe 'field declarations' do
    it 'requires a type' do
      expect { Class.new(FlavourSaver::Node) { value :name } }.to raise_error(ArgumentError)
    end

    it "doesn't allow a value to be typed as a node" do
      expect { Class.new(FlavourSaver::Node) { value :call, FlavourSaver::CallNode } }
        .to raise_error(ArgumentError, /type can't be a Node/)
    end

    it 'requires a child to be typed as a node' do
      expect { Class.new(FlavourSaver::Node) { child :name, [String] } }
        .to raise_error(ArgumentError, /type must be a Node/)
    end

    it 'requires the type to be a class or a class in an array' do
      expect { Class.new(FlavourSaver::Node) { child :calls, [FlavourSaver::CallNode, FlavourSaver::StringNode] } }
        .to raise_error(ArgumentError, /must have a class, or a class in an array/)
    end
  end
end
