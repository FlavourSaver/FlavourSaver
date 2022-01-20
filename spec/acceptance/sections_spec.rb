require 'tilt'
require 'flavour_saver'

describe 'Fixture: sections.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:context) { Struct.new(:name, :names, :order).new }
  let(:template) { File.expand_path('../../fixtures/sections.hbs', __FILE__) }

  it 'renders correctly when given a name' do
    context.name = 'Alan'
    expect(subject).to eq "Say hello to Alan."
  end

  it 'renders correctly when given a list of names' do
    context.names = ['Foo', 'Bar']
    expect(subject).to eq "* Foo * Bar"
  end

  it 'renders correctly when given an order' do
    class Order; def number; 1234; end; end
    context.order = Order.new
    expect(subject).to eq 'Number: 1234'
  end
end

