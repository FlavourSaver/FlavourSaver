require 'tilt'
require 'flavour_saver'

describe do
  subject { Tilt.new(template).render(context) }
  let(:template) { File.expand_path('../../fixtures/backtrack.hbs', __FILE__) }
  let(:context)  { stub(:context) }

  it 'renders correctly' do
    person = stub(:person)
    context.should_receive(:person).and_return(person)
    person.should_receive(:name).and_return('Alan')
    subject.should == "hello world\n"
  end
end
