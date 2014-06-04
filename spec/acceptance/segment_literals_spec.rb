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
      foos[1].should_receive(:bar).and_return('two')

      context.stub(:foos).and_return(foos)
      subject.should == 'two'
    end
  end
end
