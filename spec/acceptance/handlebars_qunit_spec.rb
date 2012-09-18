# These are the original Handlebars.js qunit acceptance tests, ported
# to run against FlavourSaver.  Yes, this is a more brittle way of
# doing it.

require 'active_support'
ActiveSupport::SafeBuffer

require 'flavour_saver'

describe FlavourSaver do
  let(:context) { stub(:context) }
  subject { FS.evaluate(template, context) }

  describe "basic context" do
    before { FS.register_helper(:link_to) { "<a>#{context}</a>" } }
    after  { FS::Helpers.reset_helpers }

    describe 'most basic' do
      let(:template) { "{{foo}}" }

      it 'returns "foo"' do
        context.stub!(:foo).and_return('foo')
        subject.should == 'foo'
      end
    end

    describe 'compiling with a basic context' do
      let(:template) { "Goodbye\n{{cruel}}\n{{world}}!" }

      it 'it works if all the required keys are provided' do
        context.should_receive(:cruel).and_return('cruel')
        context.should_receive(:world).and_return('world')
        subject.should == "Goodbye\ncruel\nworld!"
      end
    end

    describe 'comments' do
      let(:template) {"{{! Goodbye}}Goodbye\n{{cruel}}\n{{world}}!"}

      it 'comments are ignored' do
        context.should_receive(:cruel).and_return('cruel')
        context.should_receive(:world).and_return('world')
        subject.should == "Goodbye\ncruel\nworld!"
      end
    end

    describe 'boolean' do
      let(:template) { "{{#goodbye}}GOODBYE {{/goodbye}}cruel {{world}}!" }

      it 'booleans show the contents when true' do
        context.stub(:goodbye).and_return(true)
        context.stub(:world).and_return('world')
        subject.should == "GOODBYE cruel world!"
      end

      it 'booleans do not show the contents when false' do
        context.stub(:goodbye).and_return(false)
        context.stub(:world).and_return('world')
        subject.should == "cruel world!"
      end
    end

    describe 'zeros' do
      describe '{num1: 42, num2: 0}' do
        let (:template) { "num1: {{num1}}, num2: {{num2}}" }

        it 'should compile to "num1: 42, num2: 0"' do
          context.stub(:num1).and_return(42)
          context.stub(:num2).and_return(0)
          subject.should == 'num1: 42, num2: 0'
        end
      end

      describe 0 do
        let (:template) { 'num: {{.}}' }

        it 'should compile to "num: 0"' do
          FlavourSaver.evaluate(template,0).should == 'num: 0'
        end
      end

      describe '{num1: {num2: 0}}' do
        let(:template) { 'num: {{num1/num2}}' }

        it 'should compile to "num: 0"' do
          context.stub_chain(:num1, :num2).and_return(0)
          subject.should == 'num: 0'
        end
      end
    end

    describe 'newlines' do
      describe '\n' do
        let(:template) { "Alan's\nTest" }

        it 'works' do
          subject.should == "Alan's\nTest"
        end
      end

      describe '\r' do
        let(:template) { "Alan's\rTest" }

        it 'works' do
          subject.should == "Alan's\rTest"
        end
      end
    end

    describe 'esaping text' do
      describe 'apostrophes' do
        let(:template) {"Awesome's"}

        it "text is escapes so that it doesn't get caught in single quites" do
          subject.should == "Awesome's"
        end
      end

      describe 'backslashes' do
        let(:template) { "Awesome \\" }

        it "text is escaped so that the closing quote can't be ignored" do
          subject.should == "Awesome \\"
        end
      end

      describe 'more backslashes' do
        let(:template) { "Awesome\\\\ foo" }

        it "text is escapes so that it doesn't mess up the backslashes" do
          subject.should == "Awesome\\\\ foo"
        end
      end

      describe 'helper output containing backslashes' do
        let(:template) { "Awesome {{foo}}" }

        it "text is escaped so that it doesn't mess up backslashes" do
          context.stub(:foo).and_return('\\')
          subject.should == "Awesome \\"
        end
      end

      describe 'doubled quotes' do
        let(:template) { ' " " ' }

        it "double quotes never produce invalid javascript" do
          subject.should == ' " " '
        end
      end
    end

    describe 'escaping expressions' do
      describe 'expressions with 3 handlebars' do
        let(:template) { "{{{awesome}}}" }

        it "shouldn't be escaped" do
          context.stub(:awesome).and_return("&\"\\<>")
          subject.should == "&\"\\<>"
        end
      end

      describe 'expressions with {{& handlebars' do
        let(:template) { "{{&awesome}}" }

        it "shouldn't be escaped" do
          context.stub(:awesome).and_return("&\"\\<>")
          subject.should == "&\"\\<>"
        end
      end

      describe 'expressions' do
        let(:template) { "{{awesome}}" }

        it "should be escaped" do
          context.stub(:awesome).and_return("&\"'`\\<>")
          subject.should == "&amp;&quot;&#x27;&#x60;\\&lt;&gt;"
        end
      end

      describe 'ampersands' do
        let(:template) { "{{awesome}}" }

        it "should be escaped" do
          context.stub(:awesome).and_return("Escaped, <b> looks like: &lt;b&gt;")
          subject.should == "Escaped, &lt;b&gt; looks like: &amp;lt;b&amp;gt;"
        end
      end
    end

    describe "functions returning safe strings" do
      let(:template) { "{{awesome}}" }

      it "shouldn't be escaped" do
        context.stub(:awesome).and_return("&\"\\<>".html_safe)
        subject.should == "&\"\\<>"
      end
    end

    describe 'functions' do
      let(:template) { "{{awesome}}" }

      it "are called and render their output" do
        context.stub(:awesome).and_return("Awesome")
        subject.should == "Awesome"
      end
    end

    describe 'paths with hyphens' do
      describe '{{foo-bar}}' do
        let(:template) { "{{foo-bar}}" } 

        it 'paths can contain hyphens (-)' do
          context.should_receive(:[]).with('foo-bar').and_return('baz')
          subject.should == 'baz'
        end
      end

      describe '{{foo.foo-bar}}' do
        let(:template) { "{{foo.foo-bar}}" } 

        it 'paths can contain hyphens (-)' do
          context.stub_chain(:foo, :[]).with('foo-bar').and_return(proc { 'baz' })
          subject.should == 'baz'
        end
      end

      describe '{{foo/foo-bar}}' do
        let(:template) { "{{foo/foo-bar}}" } 

        it 'paths can contain hyphens (-)' do
          context.stub_chain(:foo, :[]).with('foo-bar').and_return('baz')
          subject.should == 'baz'
        end
      end

      describe 'nested paths' do 
        let(:template) {"Goodbye {{alan/expression}} world!"}

        it 'access nested object' do
          context.stub_chain(:alan, :expression).and_return('beautiful')
          subject.should == 'Goodbye beautiful world!'
        end
      end

      describe 'nested path with empty string value' do
        let(:template) {"Goodbye {{alan/expression}} world!"}

        it 'access nested object' do
          context.stub_chain(:alan, :expression).and_return('')
          subject.should == 'Goodbye  world!'
        end
      end

      describe 'literal paths' do
        let(:template) { "Goodbye {{[@alan]/expression}} world!" }

        it 'literal paths can be used' do
          alan = stub(:alan)
          context.should_receive(:[]).with('@alan').and_return(alan)
          alan.should_receive(:expression).and_return('beautiful')
          subject.should == 'Goodbye beautiful world!'
        end
      end

      describe 'complex but empty paths' do
        let(:template) { '{{person/name}}' }

        it 'returns empty string from nested paths' do
          context.stub_chain(:person,:name).and_return('')
          subject.should == ''
        end

        it 'returns empty string from nil objects' do
          context.stub_chain(:person,:name)
          subject.should == ''
        end
      end

      describe '"this" keyword' do
        describe 'in a block' do 
          let(:template) { "{{#goodbyes}}{{this}}{{/goodbyes}}" }

          it 'evaluates to the current context' do
            context.stub(:goodbyes).and_return(["goodbye", "Goodbye", "GOODBYE"])
            subject.should == "goodbyeGoodbyeGOODBYE"
          end
        end

        describe 'in a block in a path' do
          let(:template) { "{{#hellos}}{{this/text}}{{/hellos}}" }

          it 'evaluates in more complex paths' do
            hellos = []
            hellos << stub(:hello)
            hellos[0].should_receive(:text).and_return('hello')
            hellos << stub(:Hello)
            hellos[1].should_receive(:text).and_return('Hello')
            hellos << stub(:HELLO)
            hellos[2].should_receive(:text).and_return('HELLO')
            context.stub(:hellos).and_return(hellos)
            subject.should == "helloHelloHELLO"
          end
        end
      end

      describe 'this keyword in helpers' do
        before { FS.register_helper(:foo) { |value| "bar #{value}" } }
        after  { FS.reset_helpers }

        describe 'this keyword in arguments' do
          let(:template) { "{{#goodbyes}}{{foo this}}{{/goodbyes}}" }

          it 'evaluates to current context' do
            context.stub(:goodbyes).and_return(["goodbye", "Goodbye", "GOODBYE"])
            subject.should == "bar goodbyebar Goodbyebar GOODBYE"
          end
        end

        describe 'this keyword in object path arguments' do
          let(:template) { "{{#hellos}}{{foo this/text}}{{/hellos}}" }

          it 'evaluates to current context' do
            hellos = []
            hellos << stub(:hello)
            hellos[0].should_receive(:text).and_return('hello')
            hellos << stub(:Hello)
            hellos[1].should_receive(:text).and_return('Hello')
            hellos << stub(:HELLO)
            hellos[2].should_receive(:text).and_return('HELLO')
            context.stub(:hellos).and_return(hellos)
            subject.should == "bar hellobar Hellobar HELLO"
          end
        end
      end
    end
  end

  describe 'Inverted sections' do
    let(:template) { "{{#goodbyes}}{{this}}{{/goodbyes}}{{^goodbyes}}Right On!{{/goodbyes}}" }

    describe 'with unset value' do
      it 'renders' do
        context.stub(:goodbyes)
        subject.should == 'Right On!'
      end
    end

    describe 'with false value' do
      it 'renders' do
        context.stub(:goodbyes).and_return(false)
        subject.should == 'Right On!'
      end
    end

    describe 'with an empty set' do
      it 'renders' do
        context.stub(:goodbyes).and_return([])
        subject.should == 'Right On!'
      end
    end
  end

  describe 'Blocks' do
    let(:template) { "{{#goodbyes}}{{text}}! {{/goodbyes}}cruel {{world}}!" }

    it 'arrays iterate the contents with non-empty' do
      goodbyes = []
      goodbyes << stub(:goodbye)
      goodbyes[0].should_receive(:text).and_return('goodbye')
      goodbyes << stub(:Goodbye)
      goodbyes[1].should_receive(:text).and_return('Goodbye')
      goodbyes << stub(:GOODBYE)
      goodbyes[2].should_receive(:text).and_return('GOODBYE')
      context.stub(:goodbyes).and_return(goodbyes)
      context.stub(:world).and_return('world')
      subject.should == "goodbye! Goodbye! GOODBYE! cruel world!"
    end

    it 'ignores the contents when the array is empty' do
      context.stub(:goodbyes).and_return([])
      context.stub(:world).and_return('world')
      subject.should == "cruel world!"
    end

    describe 'array with @index' do
      let(:template) {"{{#goodbyes}}{{@index}}. {{text}}! {{/goodbyes}}cruel {{world}}!"}

      it 'the @index variable is used' do
        goodbyes = []
        goodbyes << stub(:goodbye)
        goodbyes[0].should_receive(:text).and_return('goodbye')
        goodbyes << stub(:Goodbye)
        goodbyes[1].should_receive(:text).and_return('Goodbye')
        goodbyes << stub(:GOODBYE)
        goodbyes[2].should_receive(:text).and_return('GOODBYE')
        context.stub(:goodbyes).and_return(goodbyes)
        context.stub(:world).and_return('world')
        subject.should == "0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!"
      end
    end

    describe 'empty block' do
      let(:template) { "{{#goodbyes}}{{/goodbyes}}cruel {{world}}!" }

      it 'arrays iterate the contents with non-empty' do
        goodbyes = []
        goodbyes << stub(:goodbye)
        goodbyes[0].stub(:text).and_return('goodbye')
        goodbyes << stub(:Goodbye)
        goodbyes[1].stub(:text).and_return('Goodbye')
        goodbyes << stub(:GOODBYE)
        goodbyes[2].stub(:text).and_return('GOODBYE')
        context.stub(:goodbyes).and_return(goodbyes)
        context.stub(:world).and_return('world')
        subject.should == "cruel world!"
      end

      it 'ignores the contents when the array is empty' do
        context.stub(:goodbyes).and_return([])
        context.stub(:world).and_return('world')
        subject.should == "cruel world!"
      end
    end

    describe 'nested iteration'

    describe 'block with complex lookup' do
      let(:template) {"{{#goodbyes}}{{text}} cruel {{../name}}! {{/goodbyes}}"}

      it 'templates can access variables in contexts up the stack with relative path syntax' do
        context.stub(:name).and_return('Alan')
        goodbyes = []
        goodbyes << stub(:goodbye)
        goodbyes[0].should_receive(:text).and_return('goodbye')
        goodbyes << stub(:Goodbye)
        goodbyes[1].should_receive(:text).and_return('Goodbye')
        goodbyes << stub(:GOODBYE)
        goodbyes[2].should_receive(:text).and_return('GOODBYE')
        context.stub(:goodbyes).and_return(goodbyes)
        subject.should == "goodbye cruel Alan! Goodbye cruel Alan! GOODBYE cruel Alan! "
      end
    end

    describe 'helper with complex lookup' do
      let(:template) {"{{#goodbyes}}{{{link ../prefix}}}{{/goodbyes}}"}
      before do
        FS.register_helper(:link) do |prefix|
          "<a href='#{prefix}/#{url}'>#{text}</a>"
        end
      end
      after { FS.reset_helpers }

      it 'renders correctly' do
        context.stub(:prefix).and_return('/root')
        goodbyes = []
        goodbyes << stub(:Goodbye)
        goodbyes[0].should_receive(:text).and_return('Goodbye')
        goodbyes[0].should_receive(:url).and_return('goodbye')
        context.stub(:goodbyes).and_return(goodbyes)
        subject.should == "<a href='/root/goodbye'>Goodbye</a>"
      end
    end
  end
end
