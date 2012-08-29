module BasicSteps
  step 'a simple handlebars expression' do
    @expression = '{{simple_expression}}'
    @context = stub(:context)
    @context.stub(:simple_expression).and_return('WAT')
  end

  step 'I evaluate the expression' do
    FlavourSaver.evaluate(@expression, @context).should == 'WAT'
  end
end

RSpec.configure { |c| c.include BasicSteps }
