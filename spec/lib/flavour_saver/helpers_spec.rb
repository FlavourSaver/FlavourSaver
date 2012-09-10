require 'flavour_saver/helpers'

describe FlavourSaver::Helpers do
  before(:each) { FlavourSaver::Helpers.send(:instance_variable_set, :@registered_helpers, nil) }

  describe '#registered_helpers' do
    it 'should be empty by default' do
      subject.registered_helpers.should be_empty
    end
  end

  describe '#register_helper' do
    it 'takes the provided name and block and stashes them' do
      world = proc { 'world' }
      subject.register_helper(:hello,&world)
      subject.registered_helpers.should include(hello: world)
    end
  end

  describe '#deregister_helper' do
    it 'removes the specified helper' do
      subject.register_helper(:hello) {}
      subject.deregister_helper(:hello)
      subject.registered_helpers.keys.should_not include(:hello)
    end
  end

  describe 'Defaults' do
    subject { Class.new(FlavourSaver::Helpers::Defaults).new }

    describe '#with' do
      it "yields it's first argument" do
        expect { |b| subject.with(:test,&b) }.to yield_with_args(:test)
      end
    end

    describe '#each' do
      it 'yeilds each element of a collection' do
        expect { |b| subject.each([:a,:b,:c],&b) }.to yield_successive_args(:a,:b,:c)
      end
    end

    describe '#if' do
      it "yields if it's argument is truthy" do
        expect { |b| subject.if(true, &b) }.to yield_control
      end

      it "doesn't yield if it's argument is falsy" do
        expect { |b| subject.if(false, &b) }.not_to yield_control
      end

      it 'handles else'
    end

    describe '#unless' do
      it "calls #if with it's argument negated" do
        subject.should_receive(:if).with(false)
        subject.unless(true)
      end
    end

    describe '#this' do
      it 'returns self' do
        subject.this.should == subject
      end
    end
  end

end
