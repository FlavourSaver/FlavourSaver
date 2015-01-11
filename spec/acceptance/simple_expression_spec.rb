require 'tilt'
require 'flavour_saver'

describe 'Fixture: simple_expression.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/simple_expression.hbs', __FILE__) }
  let(:context)  { double(:context) }

  it 'renders correctly' do
    context.should_receive(:hello).and_return('hello world')
    subject.should == "hello world"
  end

  it 'renders nothing if undefined' do
    subject.should == ""
  end
end
