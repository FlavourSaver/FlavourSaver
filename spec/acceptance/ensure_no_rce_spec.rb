require 'tilt'
require 'flavour_saver'

describe "Can't call methods that the context doesn't respond to" do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { '{{system "ls"}}' }
  let(:context)  { double(:context) }

  it 'renders correctly' do
    expect(Kernel).not_to receive(:system)
    expect { subject }.to raise_error
  end
end

describe "Can't eval arbitrary Ruby code" do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:template) { '{{eval "puts 1 + 1"}}' }
  let(:context)  { double(:context) }

  it 'renders correctly' do
    expect(Kernel).not_to receive(:eval)
    expect { subject }.to raise_error
  end
end


