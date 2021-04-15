require 'tilt'
require 'flavour_saver'

describe 'Fixture: backtrack.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/backtrack.hbs', __FILE__) }
  let(:context) { Struct.new(:person,:company).new }

  it 'renders correctly' do
    context.person = Struct.new(:name).new('Alan')
    context.company = Struct.new(:name).new('Rad, Inc.')
    expect(subject).to eq "Alan - Rad, Inc."
  end
end
