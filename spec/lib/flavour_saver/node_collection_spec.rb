require 'flavour_saver'

describe FlavourSaver::NodeCollection do
  let(:collection) { FlavourSaver.parse(FlavourSaver.lex(File.read(File.expand_path("../../../fixtures/#{template}", __FILE__)))).items }
  let(:template) { 'comment.hbs' }

  # context 'the collection contains no block nodes' do
  #   it "leaves the collection unchanged when it contains no block nodes" do
  #     FlavourSaver::NodeCollection.new(collection).to_a.should == collection.dup
  #   end
  # end

  context 'the collection contains blocks' do
    let(:template) { 'multi_level_helper.hbs' }

    it "replaces the block start node with a collection containing itself and it's children" do
      FlavourSaver::NodeCollection.new(collection).to_a.should == []
    end
  end
  

  describe '#toggle' do
    let(:collection) { (0..9).to_a }
    subject { FlavourSaver::NodeCollection.new(collection) }
     
    it 'collects once the block evals to true' do
      subject.toggle { |i| i == 3 }.should == [0,1,2,[3,4,5,6,7,8,9]]
    end

    it 'stops collecting when the block evals to true again' do
      subject.toggle { |i| (i==3) || (i==7) }.should == [0,1,2,[3,4,5,6],7,8,9]
    end
  end

end
