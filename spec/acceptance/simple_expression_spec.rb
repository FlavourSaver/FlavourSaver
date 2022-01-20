require 'tilt'
require 'flavour_saver'

describe 'Fixture: simple_expression.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/simple_expression.hbs', __FILE__) }
  let(:context)  { double(:context) }

  it 'renders correctly' do
    expect(context).to receive(:hello).and_return('hello world')
    expect(subject).to eq "hello world"
  end

  it 'renders nothing if undefined' do
    expect(subject).to eq ""
  end
end
