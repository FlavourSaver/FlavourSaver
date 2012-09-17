require 'tilt'
require 'flavour_saver'

describe 'Fixture: multi_level_if.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/multi_level_if.hbs', __FILE__) }
  let(:context) { stub(:context) }

  it 'renders correctly when person has a name' do
    context.stub_chain(:person, :name).and_return('Alan')
    context.stub_chain(:company, :name).and_return('Rad, Inc.')
    subject.should == 'Hi Alan. - Rad, Inc.'
  end

end
