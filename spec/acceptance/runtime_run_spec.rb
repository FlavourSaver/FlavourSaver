require "flavour_saver"

describe FlavourSaver::Runtime do
  describe ".run" do
    subject do
      FlavourSaver::Runtime.run(parsed_template, context, locals, helper_names)
    end

    let(:parsed_template) { FlavourSaver.parse(FlavourSaver.lex(template)) }
    let(:context) { Object.new }
    let(:locals) { {} }
    let(:helper_names) { [] }

    describe "with a local helper" do
      let(:template) { "{{n}} is {{#is_even n}}even{{else}}odd{{/is_even}}" }
      let(:context_class) { Struct.new(:n) }
      let(:context) { context_class.new(24) }

      it "uses the helper" do
        is_even_helper = proc { |n| n % 2 == 0 }

        locals[:is_even] = is_even_helper
        subject.should == "24 is even"
      end
    end
  end
end
