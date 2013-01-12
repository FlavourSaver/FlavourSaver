require 'tilt'
require 'flavour_saver'

describe 'Fixture: one_character_identifier.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { File.expand_path('../../fixtures/one_character_identifier.hbs', __FILE__) }
  let(:context)  { stub(:context) }

  it 'renders correctly' do
    context.should_receive(:a).and_return('foo')
    subject.should == "foo"
  end
end
