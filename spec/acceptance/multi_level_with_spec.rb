require 'tilt'
require 'flavour_saver'

describe 'Fixture: multi_level_with.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/multi_level_with.hbs', __FILE__) }
  let(:context) { Struct.new(:person,:company).new }

  it 'renders correctly when person has a name' do
    context.person = Struct.new(:name).new('Alan')
    context.company = Struct.new(:name).new('Rad, Inc.')
    subject.should == 'Alan - Rad, Inc.'
  end

end
