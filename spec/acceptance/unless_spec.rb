require 'tilt'
require 'flavour_saver'

describe 'Fixture: unless.hbs' do
  subject { Tilt.new(template).render(context).gsub(/[\s\r\n]+/, ' ').strip }
  let(:context) { Struct.new(:value).new }
  let(:template) { File.expand_path('../../fixtures/unless.hbs', __FILE__) }

  it "renders the unless block when given false" do
    context.value = false
    expect(subject).to eq "The given value is falsy: false."
  end

  it 'renders the unless block when given nil' do
    context.value = nil
    expect(subject).to eq "The given value is falsy: ."
  end

  it "renders the unless block when given an empty string" do
    context.value = ""
    expect(subject).to eq "The given value is falsy: ."
  end

  it "renders the unless block when given a zero" do
    context.value = 0
    expect(subject).to eq "The given value is falsy: 0."
  end

  it "renders the unless block when given an empty array" do
    context.value = []
    expect(subject).to eq "The given value is falsy: []."
  end

  it "renders the else block when given a string" do
    context.value = "Alan"
    expect(subject).to eq "The given value is truthy: Alan."
  end

  it "renders the else block when given a number greater than zero" do
    context.value = 1
    expect(subject).to eq "The given value is truthy: 1."
  end

  it "renders the else block when given an array that is not empty" do
    context.value = [1]
    expect(subject).to eq "The given value is truthy: [1]."
  end
end
