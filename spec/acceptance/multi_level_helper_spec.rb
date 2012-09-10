require 'tilt'
require 'flavour_saver'

describe do
  subject { Tilt.new(template).render(context) }
  let(:template) { File.expand_path('../../fixtures/multi_level_helper.hbs', __FILE__) }

  it 'renders correctly when person has a name' do
    person = Struct.new(:name).new('Alan')
    company = Struct.new(:name).new('Rad, Inc.')
    context = Struct.new(:person,:company).new(person, company)
    Tilt.new(template).render(context).should == "\n  Alan\n  Rad, Inc.\n\n"
  end

  it 'renders correctly when person has no name' do
    person = Struct.new(:name).new
    company = Struct.new(:name).new('Rad, Inc.')
    context = Struct.new(:person,:company).new(person, company)
    Tilt.new(template).render(context).should == "\n  \n  Rad, Inc.\n\n"
  end
end
