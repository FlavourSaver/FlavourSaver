require 'tilt'
require 'flavour_saver'

describe 'Fixture: custom_helper.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/custom_helper.hbs', __FILE__) }
  let(:context)  { double(:context) }

  it 'renders correctly' do
    FlavourSaver.register_helper(:say_what_again) do
      'What?'
    end
    expect(subject).to eq "What?"
  end
end
