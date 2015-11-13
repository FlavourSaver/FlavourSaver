require 'tilt'
require 'flavour_saver'

describe 'Fixture: raw.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/raw.hbs', __FILE__) }
  let(:context)  { double(:context) }

  it 'renders correctly' do
    subject.should == "{{=if brokensyntax}"
  end
end
