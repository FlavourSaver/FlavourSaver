require 'tilt'
require 'flavour_saver'

describe 'Fixture: backtrack.hbs' do
  subject { Tilt.new(template).render(context) }
  let(:template) { File.expand_path('../../fixtures/backtrack.hbs', __FILE__) }

  it 'renders correctly' do
    person = Struct.new(:name).new('Alan')
    company = Struct.new(:name).new('Rad, Inc.')
    context = Struct.new(:person,:company).new(person, company)
    Tilt.new(template).render(context).should == "\n  Alan\n  Rad, Inc.\n\n"
  end
end
