require 'tilt'
require 'flavour_saver'

describe 'Subexpressions' do

  subject { Tilt['handlebars'].new{ template }.render(context).gsub(/[\s\r\n]+/, ' ').strip }
  
  let(:context)  { double(:context) }
  before(:all) do
    FlavourSaver.register_helper(:sum) { |a,b| a + b}
  end
  context "simple subexpression" do
    let(:template) { "{{sum 1 (sum 1 1)}}" }
    specify{subject.should == "3"}
  end

  context "nested subexpressions" do
    let(:template) { "{{sum 1 (sum 1 (sum 1 1))}}" }
    specify{subject.should == "4"}
  end

  context "subexpression as argument" do
    before {FlavourSaver.register_helper(:cents) { |a| a[:total] + 10}}
    let(:template) { "{{cents total=(sum 1 1)}}" }
    specify{subject.should == "12"}
  end

  context "subexpression in block" do
    before {FlavourSaver.register_helper(:repeat) do |a, &block| 
      s = ''
      a.times {s += block.call.contents}
      s
    end}
    let(:template) { "{{#repeat (sum 1 2)}}*{{/repeat}}" }
    specify{subject.should == "***"}
  end
  
end
