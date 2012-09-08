module BasicSteps
  step 'a simple handlebars expression' do
    @expression = '{{simple_expression}}'
    @context = stub(:context)
    @context.stub(:simple_expression).and_return('WAT')
  end

  step 'I evaluate the expression' do
    @result = FlavourSaver.evaluate(@expression, @context)
  end

  step 'I should see its result' do
    @result.should == 'WAT'
  end
end

RSpec.configure { |c| c.include BasicSteps }
