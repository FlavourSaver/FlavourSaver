require 'flavour_saver'

describe FlavourSaver do
  subject { FS.evaluate(template, context) }

  let(:context) { double(:context) }

  after do
    FS.reset_helpers
    FS.reset_partials
  end

  describe 'segment literal array access' do
    let(:template) { '{{foos.[1].bar}}' }

    it 'returns "two"' do
      foos = []
      foos << double(:foo)
      foos << double(:foo)
      expect(foos[1]).to receive(:bar).and_return('two')

      allow(context).to receive(:foos).and_return(foos)
      expect(subject).to eq 'two'
    end
  end
end
