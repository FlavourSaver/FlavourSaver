require 'tilt'
require 'flavour_saver'

describe 'Fixture: multi_level_if.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/multi_level_if.hbs', __FILE__) }
  let(:context) { Struct.new(:person,:company).new }

  it 'renders correctly when person has a name' do
    person = Struct.new(:name).new('Alan')
    company = Struct.new(:name).new('Rad, Inc.')
    context.person = person
    context.company = company
    subject.should == 'Hi Alan. - Rad, Inc.'
  end

end
