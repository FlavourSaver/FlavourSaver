require 'tilt'
require 'flavour_saver'

describe 'Fixture: multi_level_helper.hbs' do
  subject { Tilt.new(template).render(context) }
  let(:template) { File.expand_path('../../fixtures/multi_level_helper.hbs', __FILE__) }

  it 'renders correctly when person has a name' do
    person = Struct.new(:name).new('Alan')
    company = Struct.new(:name).new('Rad, Inc.')
    context = Struct.new(:person,:company).new(person, company)
    Tilt.new(template).render(context).strip.should == 'Alan - Rad, Inc'
  end

end
