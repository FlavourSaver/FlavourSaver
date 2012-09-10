require 'tilt'
require 'flavour_saver'

describe 'Fixture: simple_expression.hbs' do
  subject { Tilt.new(template).render(context) }
  let(:template) { File.expand_path('../../fixtures/simple_expression.hbs', __FILE__) }
  let(:context)  { stub(:context) }

  it 'renders correctly' do
    context.should_receive(:hello).and_return('hello world')
    subject.should == "hello world\n"
  end
end
