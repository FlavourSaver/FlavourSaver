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
end
