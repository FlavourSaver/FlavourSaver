# These are the original Handlebars.js qunit acceptance tests, ported
# to run against FlavourSaver.  Yes, this is a more brittle way of
# doing it.

require 'active_support'
ActiveSupport::SafeBuffer

require 'flavour_saver'

describe FlavourSaver do
  let(:context) { double(:context) }
  subject { FS.evaluate(template, context) }
  after do
    FS.reset_helpers
    FS.reset_partials
  end

  describe "basic context" do
    before { FS.register_helper(:link_to) { "<a>#{context}</a>" } }

    describe 'most basic' do
      let(:template) { "{{foo}}" }

      it 'returns "foo"' do
        allow(context).to receive(:foo).and_return('foo')
        expect(subject).to eq 'foo'
      end
    end

    describe 'compiling with a basic context' do
      let(:template) { "Goodbye\n{{cruel}}\n{{world}}!" }

      it 'it works if all the required keys are provided' do
        expect(context).to receive(:cruel).and_return('cruel')
        expect(context).to receive(:world).and_return('world')
        expect(subject).to eq "Goodbye\ncruel\nworld!"
      end
    end

    describe 'comments' do
      let(:template) {"{{! Goodbye}}Goodbye\n{{cruel}}\n{{world}}!"}

      it 'comments are ignored' do
        expect(context).to receive(:cruel).and_return('cruel')
        expect(context).to receive(:world).and_return('world')
        expect(subject).to eq "Goodbye\ncruel\nworld!"
      end
    end

    describe 'boolean' do
      let(:template) { "{{#goodbye}}GOODBYE {{/goodbye}}cruel {{world}}!" }

      it 'booleans show the contents when true' do
        allow(context).to receive(:goodbye).and_return(true)
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "GOODBYE cruel world!"
      end

      it 'booleans do not show the contents when false' do
        allow(context).to receive(:goodbye).and_return(false)
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "cruel world!"
      end
    end

    describe 'zeros' do
      describe '{num1: 42, num2: 0}' do
        let (:template) { "num1: {{num1}}, num2: {{num2}}" }

        it 'should compile to "num1: 42, num2: 0"' do
          allow(context).to receive(:num1).and_return(42)
          allow(context).to receive(:num2).and_return(0)
          expect(subject).to eq 'num1: 42, num2: 0'
        end
      end

      describe 0 do
        let (:template) { 'num: {{.}}' }

        it 'should compile to "num: 0"' do
          expect(FlavourSaver.evaluate(template,0)).to eq 'num: 0'
        end
      end

      describe '{num1: {num2: 0}}' do
        let(:template) { 'num: {{num1/num2}}' }

        it 'should compile to "num: 0"' do
          allow(context).to receive_message_chain(:num1, :num2).and_return(0)
          expect(subject).to eq 'num: 0'
        end
      end
    end

    describe 'newlines' do
      describe '\n' do
        let(:template) { "Alan's\nTest" }

        it 'works' do
          expect(subject).to eq "Alan's\nTest"
        end
      end

      describe '\r' do
        let(:template) { "Alan's\rTest" }

        it 'works' do
          expect(subject).to eq "Alan's\rTest"
        end
      end
    end

    describe 'esaping text' do
      describe 'apostrophes' do
        let(:template) {"Awesome's"}

        it "text is escapes so that it doesn't get caught in single quites" do
          expect(subject).to eq "Awesome's"
        end
      end

      describe 'backslashes' do
        let(:template) { "Awesome \\" }

        it "text is escaped so that the closing quote can't be ignored" do
          expect(subject).to eq "Awesome \\"
        end
      end

      describe 'more backslashes' do
        let(:template) { "Awesome\\\\ foo" }

        it "text is escapes so that it doesn't mess up the backslashes" do
          expect(subject).to eq "Awesome\\\\ foo"
        end
      end

      describe 'helper output containing backslashes' do
        let(:template) { "Awesome {{foo}}" }

        it "text is escaped so that it doesn't mess up backslashes" do
          allow(context).to receive(:foo).and_return('\\')
          expect(subject).to eq "Awesome \\"
        end
      end

      describe 'doubled quotes' do
        let(:template) { ' " " ' }

        it "double quotes never produce invalid javascript" do
          expect(subject).to eq ' " " '
        end
      end
    end

    describe 'escaping expressions' do
      describe 'expressions with 3 handlebars' do
        let(:template) { "{{{awesome}}}" }

        it "shouldn't be escaped" do
          allow(context).to receive(:awesome).and_return("&\"\\<>")
          expect(subject).to eq "&\"\\<>"
        end
      end

      describe 'expressions with {{& handlebars' do
        let(:template) { "{{&awesome}}" }

        it "shouldn't be escaped" do
          allow(context).to receive(:awesome).and_return("&\"\\<>")
          expect(subject).to eq "&\"\\<>"
        end
      end

      describe 'expressions' do
        let(:template) { "{{awesome}}" }

        it "should be escaped" do
          allow(context).to receive(:awesome).and_return("&\"'`\\<>")
          if RUBY_VERSION >= '2.0.0'
            expect(subject).to eq "&amp;&quot;&#39;&#x60;\\&lt;&gt;"
          else
            expect(subject).to eq "&amp;&quot;&#x27;&#x60;\\&lt;&gt;"
          end
        end
      end

      describe 'ampersands' do
        let(:template) { "{{awesome}}" }

        it "should be escaped" do
          allow(context).to receive(:awesome).and_return("Escaped, <b> looks like: &lt;b&gt;")
          expect(subject).to eq "Escaped, &lt;b&gt; looks like: &amp;lt;b&amp;gt;"
        end
      end
    end

    describe "functions returning safe strings" do
      let(:template) { "{{awesome}}" }

      it "shouldn't be escaped" do
        allow(context).to receive(:awesome).and_return("&\"\\<>".html_safe)
        expect(subject).to eq "&\"\\<>"
      end
    end

    describe 'functions' do
      let(:template) { "{{awesome}}" }

      it "are called and render their output" do
        allow(context).to receive(:awesome).and_return("Awesome")
        expect(subject).to eq "Awesome"
      end
    end

    describe 'paths with hyphens' do
      describe '{{foo-bar}}' do
        let(:template) { "{{foo-bar}}" }

        it 'paths can contain hyphens (-)' do
          expect(context).to receive(:[]).with('foo-bar').and_return('baz')
          expect(subject).to eq 'baz'
        end
      end

      describe '{{foo.foo-bar}}' do
        let(:template) { "{{foo.foo-bar}}" }

        it 'paths can contain hyphens (-)' do
          allow(context).to receive_message_chain(:foo, :[]).with('foo-bar').and_return(proc { 'baz' })
          expect(subject).to eq 'baz'
        end
      end

      describe '{{foo/foo-bar}}' do
        let(:template) { "{{foo/foo-bar}}" }

        it 'paths can contain hyphens (-)' do
          allow(context).to receive_message_chain(:foo, :[]).with('foo-bar').and_return('baz')
          expect(subject).to eq 'baz'
        end
      end

      describe 'nested paths' do
        let(:template) {"Goodbye {{alan/expression}} world!"}

        it 'access nested object' do
          allow(context).to receive_message_chain(:alan, :expression).and_return('beautiful')
          expect(subject).to eq 'Goodbye beautiful world!'
        end
      end

      describe 'nested path with empty string value' do
        let(:template) {"Goodbye {{alan/expression}} world!"}

        it 'access nested object' do
          allow(context).to receive_message_chain(:alan, :expression).and_return('')
          expect(subject).to eq 'Goodbye  world!'
        end
      end

      describe 'literal paths' do
        let(:template) { "Goodbye {{[@alan]/expression}} world!" }

        it 'literal paths can be used' do
          alan = double(:alan)
          expect(context).to receive(:[]).with('@alan').and_return(alan)
          expect(alan).to receive(:expression).and_return('beautiful')
          expect(subject).to eq 'Goodbye beautiful world!'
        end
      end

      describe 'complex but empty paths' do
        let(:template) { '{{person/name}}' }

        it 'returns empty string from nested paths' do
          allow(context).to receive_message_chain(:person,:name).and_return('')
          expect(subject).to eq ''
        end

        it 'returns empty string from nil objects' do
          allow(context).to receive_message_chain(:person,:name)
          expect(subject).to eq ''
        end
      end

      describe '"this" keyword' do
        describe 'in a block' do
          let(:template) { "{{#goodbyes}}{{this}}{{/goodbyes}}" }

          it 'evaluates to the current context' do
            allow(context).to receive(:goodbyes).and_return(["goodbye", "Goodbye", "GOODBYE"])
            expect(subject).to eq "goodbyeGoodbyeGOODBYE"
          end
        end

        describe 'in a block in a path' do
          let(:template) { "{{#hellos}}{{this/text}}{{/hellos}}" }

          it 'evaluates in more complex paths' do
            hellos = []
            hellos << double(:hello)
            expect(hellos[0]).to receive(:text).and_return('hello')
            hellos << double(:Hello)
            expect(hellos[1]).to receive(:text).and_return('Hello')
            hellos << double(:HELLO)
            expect(hellos[2]).to receive(:text).and_return('HELLO')
            allow(context).to receive(:hellos).and_return(hellos)
            expect(subject).to eq "helloHelloHELLO"
          end
        end
      end

      describe 'this keyword in helpers' do
        before { FS.register_helper(:foo) { |value| "bar #{value}" } }

        describe 'this keyword in arguments' do
          let(:template) { "{{#goodbyes}}{{foo this}}{{/goodbyes}}" }

          it 'evaluates to current context' do
            allow(context).to receive(:goodbyes).and_return(["goodbye", "Goodbye", "GOODBYE"])
            expect(subject).to eq "bar goodbyebar Goodbyebar GOODBYE"
          end
        end

        describe 'this keyword in object path arguments' do
          let(:template) { "{{#hellos}}{{foo this/text}}{{/hellos}}" }

          it 'evaluates to current context' do
            hellos = []
            hellos << double(:hello)
            expect(hellos[0]).to receive(:text).and_return('hello')
            hellos << double(:Hello)
            expect(hellos[1]).to receive(:text).and_return('Hello')
            hellos << double(:HELLO)
            expect(hellos[2]).to receive(:text).and_return('HELLO')
            allow(context).to receive(:hellos).and_return(hellos)
            expect(subject).to eq "bar hellobar Hellobar HELLO"
          end
        end
      end
    end
  end

  describe 'Inverted sections' do
    let(:template) { "{{#goodbyes}}{{this}}{{/goodbyes}}{{^goodbyes}}Right On!{{/goodbyes}}" }

    describe 'with unset value' do
      it 'renders' do
        allow(context).to receive(:goodbyes)
        expect(subject).to eq 'Right On!'
      end
    end

    describe 'with false value' do
      it 'renders' do
        allow(context).to receive(:goodbyes).and_return(false)
        expect(subject).to eq 'Right On!'
      end
    end

    describe 'with an empty set' do
      it 'renders' do
        allow(context).to receive(:goodbyes).and_return([])
        expect(subject).to eq 'Right On!'
      end
    end
  end

  describe 'Blocks' do
    let(:template) { "{{#goodbyes}}{{text}}! {{/goodbyes}}cruel {{world}}!" }

    it 'arrays iterate the contents with non-empty' do
      goodbyes = []
      goodbyes << double(:goodbye)
      expect(goodbyes[0]).to receive(:text).and_return('goodbye')
      goodbyes << double(:Goodbye)
      expect(goodbyes[1]).to receive(:text).and_return('Goodbye')
      goodbyes << double(:GOODBYE)
      expect(goodbyes[2]).to receive(:text).and_return('GOODBYE')
      allow(context).to receive(:goodbyes).and_return(goodbyes)
      allow(context).to receive(:world).and_return('world')
      expect(subject).to eq "goodbye! Goodbye! GOODBYE! cruel world!"
    end

    it 'ignores the contents when the array is empty' do
      allow(context).to receive(:goodbyes).and_return([])
      allow(context).to receive(:world).and_return('world')
      expect(subject).to eq "cruel world!"
    end

    describe 'array with @index' do
      let(:template) {"{{#goodbyes}}{{@index}}. {{text}}! {{/goodbyes}}cruel {{world}}!"}

      it 'the @index variable is used' do
        goodbyes = []
        goodbyes << double(:goodbye)
        expect(goodbyes[0]).to receive(:text).and_return('goodbye')
        goodbyes << double(:Goodbye)
        expect(goodbyes[1]).to receive(:text).and_return('Goodbye')
        goodbyes << double(:GOODBYE)
        expect(goodbyes[2]).to receive(:text).and_return('GOODBYE')
        allow(context).to receive(:goodbyes).and_return(goodbyes)
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!"
      end
    end

    describe 'empty block' do
      let(:template) { "{{#goodbyes}}{{/goodbyes}}cruel {{world}}!" }

      it 'arrays iterate the contents with non-empty' do
        goodbyes = []
        goodbyes << double(:goodbye)
        allow(goodbyes[0]).to receive(:text).and_return('goodbye')
        goodbyes << double(:Goodbye)
        allow(goodbyes[1]).to receive(:text).and_return('Goodbye')
        goodbyes << double(:GOODBYE)
        allow(goodbyes[2]).to receive(:text).and_return('GOODBYE')
        allow(context).to receive(:goodbyes).and_return(goodbyes)
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "cruel world!"
      end

      it 'ignores the contents when the array is empty' do
        allow(context).to receive(:goodbyes).and_return([])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "cruel world!"
      end
    end

    describe 'nested iteration'

    describe 'block with complex lookup' do
      let(:template) {"{{#goodbyes}}{{text}} cruel {{../name}}! {{/goodbyes}}"}

      it 'templates can access variables in contexts up the stack with relative path syntax' do
        allow(context).to receive(:name).and_return('Alan')
        goodbyes = []
        goodbyes << double(:goodbye)
        expect(goodbyes[0]).to receive(:text).and_return('goodbye')
        goodbyes << double(:Goodbye)
        expect(goodbyes[1]).to receive(:text).and_return('Goodbye')
        goodbyes << double(:GOODBYE)
        expect(goodbyes[2]).to receive(:text).and_return('GOODBYE')
        allow(context).to receive(:goodbyes).and_return(goodbyes)
        expect(subject).to eq "goodbye cruel Alan! Goodbye cruel Alan! GOODBYE cruel Alan! "
      end
    end

    describe 'helper with complex lookup' do
      let(:template) {"{{#goodbyes}}{{{link ../prefix}}}{{/goodbyes}}"}
      before do
        FS.register_helper(:link) do |prefix|
          "<a href='#{prefix}/#{url}'>#{text}</a>"
        end
      end

      it 'renders correctly' do
        allow(context).to receive(:prefix).and_return('/root')
        goodbyes = []
        goodbyes << double(:Goodbye)
        expect(goodbyes[0]).to receive(:text).and_return('Goodbye')
        expect(goodbyes[0]).to receive(:url).and_return('goodbye')
        allow(context).to receive(:goodbyes).and_return(goodbyes)
        expect(subject).to eq "<a href='/root/goodbye'>Goodbye</a>"
      end
    end

    describe 'helper with complex lookup expression' do
      let(:template) { "{{#goodbyes}}{{../name}}{{/goodbyes}}" }
      before do
        FS.register_helper(:goodbyes) do |&b|
          ["Goodbye", "goodbye", "GOODBYE"].map do |bye|
            "#{bye} #{b.call.contents}! "
          end.join('')
        end
      end

      it 'renders correctly' do
        allow(context).to receive(:name).and_return('Alan')
        expect(subject).to eq "Goodbye Alan! goodbye Alan! GOODBYE Alan! "
      end
    end

    describe 'helper with complex lookup and nested template' do
      let(:template) { "{{#goodbyes}}{{#link ../prefix}}{{text}}{{/link}}{{/goodbyes}}" }
      before do
        FS.register_helper(:link) do |prefix,&b|
          "<a href='#{prefix}/#{url}'>#{b.call.contents}</a>"
        end
      end

      it 'renders correctly' do
        allow(context).to receive(:prefix).and_return('/root')
        goodbye = double(:goodbye)
        allow(goodbye).to receive(:text).and_return('Goodbye')
        allow(goodbye).to receive(:url).and_return('goodbye')
        allow(context).to receive(:goodbyes).and_return([goodbye])
        expect(subject).to eq "<a href='/root/goodbye'>Goodbye</a>"
      end
    end

    describe 'block with deep nested complex lookup' do
      let(:template) { "{{#outer}}Goodbye {{#inner}}cruel {{../../omg}}{{/inner}}{{/outer}}" }

      example do
        goodbye = double(:goodbye)
        allow(goodbye).to receive(:text).and_return('goodbye')
        inner = double(:inner)
        allow(inner).to receive(:inner).and_return([goodbye])
        allow(context).to receive(:omg).and_return('OMG!')
        allow(context).to receive(:outer).and_return([inner])
        expect(subject).to eq "Goodbye cruel OMG!"
      end
    end

    describe 'block helper' do
      let(:template) { "{{#goodbyes}}{{text}}! {{/goodbyes}}cruel {{world}}!" }
      before do
        FS.register_helper(:goodbyes) do |&block|
          block.call.contents Struct.new(:text).new('GOODBYE')
        end
      end

      example do
        allow(context).to receive(:world).and_return('world')
      end
    end

    describe 'block helper staying in the same context' do
      let(:template) { "{{#form}}<p>{{name}}</p>{{/form}}" }
      before do
        FS.register_helper(:form) do |&block|
          "<form>#{block.call.contents}</form>"
        end
      end

      example do
        allow(context).to receive(:name).and_return('Yehuda')
        expect(subject).to eq "<form><p>Yehuda</p></form>"
      end
    end

    describe 'block helper should have context in this' do
      let(:template) { "<ul>{{#people}}<li>{{#link}}{{name}}{{/link}}</li>{{/people}}</ul>" }
      before do
        FS.register_helper(:link) do |&block|
          "<a href=\"/people/#{this.id}\">#{block.call.contents}</a>"
        end
      end
      example do
        person = Struct.new(:name, :id)
        allow(context).to receive(:people).and_return([person.new('Alan', 1), person.new('Yehuda', 2)])
        expect(subject).to eq "<ul><li><a href=\"/people/1\">Alan</a></li><li><a href=\"/people/2\">Yehuda</a></li></ul>"
      end
    end

    describe 'block helper for undefined value' do
      let(:template) { "{{#empty}}shoulnd't render{{/empty}}" }
      example do
        expect { subject }.to raise_exception(FlavourSaver::UnknownHelperException)
      end
    end

    describe 'block helper passing a new context' do
      let(:template) { "{{#form yehuda}}<p>{{name}}</p>{{/form}}" }
      before do
        FS.register_helper(:form) do |whom,&block|
          "<form>#{block.call.contents whom}</form>"
        end
      end
      example do
        allow(context).to receive_message_chain(:yehuda,:name).and_return('Yehuda')
        expect(subject).to eq "<form><p>Yehuda</p></form>"
      end
    end

    describe 'block helper passing a complex path context' do
      let(:template) { "{{#form yehuda/cat}}<p>{{name}}</p>{{/form}}" }
      before do
        FS.register_helper(:form) do |context,&block|
          "<form>#{block.call.contents context}</form>"
        end
      end
      example do
        yehuda = double(:yehuda)
        allow(yehuda).to receive(:name).and_return('Yehuda')
        allow(yehuda).to receive_message_chain(:cat,:name).and_return('Harold')
        allow(context).to receive(:yehuda).and_return(yehuda)
        expect(subject).to eq "<form><p>Harold</p></form>"
      end
    end

    describe 'nested block helpers' do
      let(:template) { "{{#form yehuda}}<p>{{name}}</p>{{#link}}Hello{{/link}}{{/form}}" }
      before do
        FS.register_helper(:link) do |&block|
          "<a href='#{name}'>#{block.call.contents}</a>"
        end
        FS.register_helper(:form) do |context,&block|
          "<form>#{block.call.contents context}</form>"
        end
      end
      example do
        allow(context).to receive_message_chain(:yehuda,:name).and_return('Yehuda')
        expect(subject).to eq "<form><p>Yehuda</p><a href='Yehuda'>Hello</a></form>"
      end
    end

    describe 'block inverted sections' do
      let(:template) { "{{#people}}{{name}}{{^}}{{none}}{{/people}}" }
      example do
        allow(context).to receive(:none).and_return("No people")
        allow(context).to receive(:people).and_return(false)
        expect(subject).to eq "No people"
      end
    end

    describe 'block inverted sections with empty arrays' do
      let(:template) { "{{#people}}{{name}}{{^}}{{none}}{{/people}}" }
      example do
        allow(context).to receive(:none).and_return('No people')
        allow(context).to receive(:people).and_return([])
        expect(subject).to eq "No people"
      end
    end

    describe 'block helpers with inverted sections' do
      let (:template) { "{{#list people}}{{name}}{{^}}<em>Nobody's here</em>{{/list}}" }
      before do
        FS.register_helper(:list) do |context,&block|
          if context.any?
            "<ul>" +
              context.map { |e| "<li>#{block.call.contents e}</li>" }.join('') +
              "</ul>"
          else
            "<p>#{block.call.inverse}</p>"
          end
        end
      end

      example 'an inverse wrapper is passed in as a new context' do
        person = Struct.new(:name)
        allow(context).to receive(:people).and_return([person.new('Alan'),person.new('Yehuda')])
        expect(subject).to eq "<ul><li>Alan</li><li>Yehuda</li></ul>"
      end

      example 'an inverse wrapper can optionally be called' do
        allow(context).to receive(:people).and_return([])
        expect(subject).to eq "<p><em>Nobody's here</em></p>"
      end

      describe 'the context of an inverse is the parent of the block' do
        let(:template) { "{{#list people}}Hello{{^}}{{message}}{{/list}}" }
        example do
          allow(context).to receive(:people).and_return([])
          allow(context).to receive(:message).and_return("Nobody's here")
          if RUBY_VERSION >= '2.0.0'
            expect(subject).to eq "<p>Nobody&#39;s here</p>"
          else
            expect(subject).to eq "<p>Nobody&#x27;s here</p>"
          end
        end
      end
    end
  end

  describe 'partials' do
    let(:template) { "Dudes: {{#dudes}}{{> dude}}{{/dudes}}" }
    before do
      FS.register_partial(:dude, "{{name}} ({{url}}) ")
    end
    example do
      person = Struct.new(:name, :url)
      allow(context).to receive(:dudes).and_return([person.new('Yehuda', 'http://yehuda'), person.new('Alan', 'http://alan')])
      expect(subject).to eq "Dudes: Yehuda (http://yehuda) Alan (http://alan) "
    end
  end

  describe 'partials with context' do
    let(:template) {"Dudes: {{>dude dudes}}"}
    before do
      FS.register_partial(:dude, "{{#this}}{{name}} ({{url}}) {{/this}}")
    end
    example "Partials can be passed a context" do
      person = Struct.new(:name, :url)
      allow(context).to receive(:dudes).and_return([person.new('Yehuda', 'http://yehuda'), person.new('Alan', 'http://alan')])
      expect(subject).to eq "Dudes: Yehuda (http://yehuda) Alan (http://alan) "
    end
  end

  describe 'partial in a partial' do
    let(:template) {"Dudes: {{#dudes}}{{>dude}}{{/dudes}}"}
    before do
      FS.register_partial(:dude, "{{name}} {{>url}} ")
      FS.register_partial(:url, "<a href='{{url}}'>{{url}}</a>")
    end
    example "Partials can be passed a context" do
      person = Struct.new(:name, :url)
      allow(context).to receive(:dudes).and_return([person.new('Yehuda', 'http://yehuda'), person.new('Alan', 'http://alan')])
      expect(subject).to eq "Dudes: Yehuda <a href='http://yehuda'>http://yehuda</a> Alan <a href='http://alan'>http://alan</a> "
    end
  end

  describe 'rendering undefined partial throws an exception' do
    let(:template) { "{{> whatever}}" }
    example do
      expect { subject }.to raise_error(FS::UnknownPartialException)
    end
  end

  describe 'rendering a function partial' do
    let(:template) { "Dudes: {{#dudes}}{{> dude}}{{/dudes}}" }
    before do
      FS.register_partial(:dude) do |context|
        "#{context.name} (#{context.url}) "
      end
    end
    example do
      person = Struct.new(:name, :url)
      allow(context).to receive(:dudes).and_return([person.new('Yehuda', 'http://yehuda'), person.new('Alan', 'http://alan')])
      expect(subject).to eq "Dudes: Yehuda (http://yehuda) Alan (http://alan) "
    end
  end

  describe 'a partial preceding a selector' do
    let(:template) { "Dudes: {{>dude}} {{another_dude}}" }
    before do
      FS.register_partial(:dude, "{{name}}")
    end
    example do
      allow(context).to receive(:name).and_return('Jeepers')
      allow(context).to receive(:another_dude).and_return('Creepers')
      expect(subject).to eq "Dudes: Jeepers Creepers"
    end
  end

  describe 'partials with literal paths' do
    let(:template) { "Dudes: {{> [dude]}}" }
    before do
      FS.register_partial(:dude, "{{name}}")
    end
    example do
      allow(context).to receive(:name).and_return('Jeepers')
      allow(context).to receive(:another_dude).and_return('Creepers')
      expect(subject).to eq "Dudes: Jeepers"
    end
  end

  describe 'partials with string paths' do
    let(:template) { "Dudes: {{> \"dude/man\"}}" }
    before do
      FS.register_partial("dude/man", "{{name}}")
    end
    example do
      allow(context).to receive(:name).and_return('Jeepers')
      allow(context).to receive(:another_dude).and_return('Creepers')
      expect(subject).to eq "Dudes: Jeepers"
    end
  end

  describe 'string literal parameters' do

    describe 'simple literals work' do
      let(:template) { "Message: {{hello \"world\" 12 true false}}" }
      before do
        FS.register_helper(:hello) do |param,times,bool1,bool2|
          times = "NaN" unless times.is_a? Integer
          bool1 = "NaB" unless bool1 == true
          bool2 = "NaB" unless bool2 == false
          "Hello #{param} #{times} times: #{bool1} #{bool2}"
        end
      end
      example do
        expect(subject).to eq "Message: Hello world 12 times: true false"
      end
    end

    describe 'using a quote in the middle of a parameter raises an error' do
      let(:template) { "Message: {{hello wo\"rld\"}}" }
      example do
        expect { subject }.to raise_error(RLTK::NotInLanguage)
      end
    end

    describe 'escaping a string is possible' do
      let(:template) { 'Message: {{{hello "\"world\""}}}' }
      before do
        FS.register_helper(:hello) do |param|
          "Hello #{param}"
        end
      end
      example do
        expect(subject).to eq 'Message: Hello \"world\"'
      end
    end

    describe 'string work with ticks' do
      let(:template) { 'Message: {{{hello "Alan\'s world"}}}' }
      before do
        FS.register_helper(:hello) do |param|
          "Hello #{param}"
        end
      end
      example do
        expect(subject).to eq "Message: Hello Alan's world"
      end
    end

  end

  describe 'multi-params' do
    describe 'simple multi-params work' do
      let(:template) { "Message: {{goodbye cruel world}}" }
      before { FS.register_helper(:goodbye) { |cruel,world| "Goodbye #{cruel} #{world}" } }
      example do
        allow(context).to receive(:cruel).and_return('cruel')
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "Message: Goodbye cruel world"
      end
    end

    describe 'block multi-params' do
      let(:template) { "Message: {{#goodbye cruel world}}{{greeting}} {{adj}} {{noun}}{{/goodbye}}" }
      before { FS.register_helper(:goodbye) { |adj,noun,&b| b.call.contents Struct.new(:greeting,:adj,:noun).new('Goodbye', adj, noun) } }
      example do
        allow(context).to receive(:cruel).and_return('cruel')
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "Message: Goodbye cruel world"
      end
    end
  end

  describe 'built-in helpers' do
    describe 'with' do
      let(:template) { "{{#with person}}{{first}} {{last}}{{/with}}" }
      example do
        allow(context).to receive(:person).and_return(Struct.new(:first,:last).new('Alan','Johnson'))
        expect(subject).to eq 'Alan Johnson'
      end
    end

    describe 'if' do
      let(:template) { "{{#if goodbye}}GOODBYE {{/if}}cruel {{world}}!" }

      example 'if with boolean argument shows the contents when true' do
        allow(context).to receive(:goodbye).and_return(true)
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "GOODBYE cruel world!"
      end

      example 'if with string argument shows the contents with true' do
        allow(context).to receive(:goodbye).and_return('dummy')
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "GOODBYE cruel world!"
      end

      example 'if with boolean argument does not show the contents when false' do
        allow(context).to receive(:goodbye).and_return(false)
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "cruel world!"
      end

      example 'if with undefined does not show the contents' do
        allow(context).to receive(:goodbye)
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "cruel world!"
      end

      example 'if with non-empty array shows the contents' do
        allow(context).to receive(:goodbye).and_return(['foo'])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "GOODBYE cruel world!"
      end

      example 'if with empty array does not show the contents' do
        allow(context).to receive(:goodbye).and_return([])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "cruel world!"
      end
    end

    describe '#each' do
      let(:template) { "{{#each goodbyes}}{{text}}! {{/each}}cruel {{world}}!" }

      example 'each with array iterates over the contents with non-empty' do
        g = Struct.new(:text)
        allow(context).to receive(:goodbyes).and_return([g.new('goodbye'), g.new('Goodbye'), g.new('GOODBYE')])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "goodbye! Goodbye! GOODBYE! cruel world!"
      end

      example 'each with array ignores the contents when empty' do
        allow(context).to receive(:goodbyes).and_return([])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "cruel world!"
      end
    end

    describe 'each with @index' do
      let(:template) { "{{#each goodbyes}}{{@index}}. {{text}}! {{/each}}cruel {{world}}!" }

      example 'the @index variable is used' do
        g = Struct.new(:text)
        allow(context).to receive(:goodbyes).and_return([g.new('goodbye'), g.new('Goodbye'), g.new('GOODBYE')])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!"
      end
    end

    describe 'each with @index in a nested block' do
      let(:template) { "{{#each goodbyes}}{{#if @last}}{{@index}}. {{/if}}{{text}}! {{/each}}cruel {{world}}!" }

      example 'the @index variable is used' do
        g = Struct.new(:text)
        allow(context).to receive(:goodbyes).and_return([g.new('goodbye'), g.new('Goodbye'), g.new('GOODBYE')])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "goodbye! Goodbye! 2. GOODBYE! cruel world!"
      end
    end

    describe 'each with @last' do
      let(:template) { "{{#each goodbyes}}{{@index}}. {{text}}! {{#if @last}}last{{/if}}{{/each}} cruel {{world}}!" }

      example 'the @last variable is used' do
        g = Struct.new(:text)
        allow(context).to receive(:goodbyes).and_return([g.new('goodbye'), g.new('Goodbye'), g.new('GOODBYE')])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "0. goodbye! 1. Goodbye! 2. GOODBYE! last cruel world!"
      end
    end

    describe 'each with @first' do
      let(:template) { "{{#each goodbyes}}{{@index}}. {{text}} {{#if @first}}first{{/if}}! {{/each}}cruel {{world}}!" }

      example 'the first variable is used' do
        g = Struct.new(:text)
        allow(context).to receive(:goodbyes).and_return([g.new('goodbye'), g.new('Goodbye'), g.new('GOODBYE')])
        allow(context).to receive(:world).and_return('world')
        expect(subject).to eq "0. goodbye first! 1. Goodbye ! 2. GOODBYE ! cruel world!"
      end
    end

    describe 'each with @root' do
      let(:template) { "{{#each goodbyes}}{{@index}}. {{text}} cruel {{@root.place}}! {{/each}}" }

      example 'the root variable is used' do
        g = Struct.new(:text)
        allow(context).to receive(:goodbyes).and_return([g.new('goodbye'), g.new('Goodbye'), g.new('GOODBYE')])
        allow(context).to receive(:place).and_return('world')
        expect(subject).to eq "0. goodbye cruel world! 1. Goodbye cruel world! 2. GOODBYE cruel world! "
      end
    end

    describe 'each with @root in a nested block' do
      let(:template) { "{{#each goodbyes}}{{@index}}. {{text}}{{#if @last}} cruel {{@root.place}}{{/if}}! {{/each}}" }

      example 'the root variable is used' do
        g = Struct.new(:text)
        allow(context).to receive(:goodbyes).and_return([g.new('goodbye'), g.new('Goodbye'), g.new('GOODBYE')])
        allow(context).to receive(:place).and_return('world')
        expect(subject).to eq "0. goodbye! 1. Goodbye! 2. GOODBYE cruel world! "
      end
    end

    describe 'log' do
      let(:template) { "{{log blah}}" }
      let(:log) { double(:log) }
      before { FS.logger = log }
      after  { FS.logger = nil }
      example do
        allow(context).to receive(:blah).and_return('whee')
        expect(log).to receive(:debug).with('FlavourSaver: whee')
        expect(subject).to eq ''
      end
    end
  end
end
