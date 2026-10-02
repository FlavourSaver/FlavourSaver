require 'tilt'
require 'flavour_saver'

# The two constructs that use the most stack per level.
describe 'Rendering at the nesting depth limit inside a Fiber' do
  subject do
    # RSpec memoizes `let` behind a mutex that another Fiber can't unlock.
    compiled = Tilt['handlebars'].new { template }
    scope = context
    Fiber.new { compiled.render(scope) }.resume
  end

  let(:max) { FlavourSaver::Parser::MAX_DEPTH }
  let(:context) do
    Struct.new(:items, :name).new.tap do |node|
      node.items = [node]
      node.name = 'leaf'
    end
  end

  before(:all) do
    FlavourSaver.register_helper(:pass) { |value, *| value }
  end

  context 'nested {{#each}} blocks' do
    let(:template) { ('{{#each items}}' * max) + '{{name}}' + ('{{/each}}' * max) }
    specify { expect(subject).to eq 'leaf' }
  end

  context 'nested hash subexpressions' do
    let(:template) { '{{pass ' + ('(pass name k=' * max) + 'name' + (')' * max) + '}}' }
    specify { expect(subject).to eq 'leaf' }
  end
end
