require 'tilt'
require 'tmpdir'
require 'fileutils'
# Object#try is mixed into Object from ActiveSupport's own module and forwards
# to public_send, so it is part of the surface under test here. Required
# explicitly rather than relying on another spec file having loaded it.
require 'active_support/core_ext/object/try'
require 'flavour_saver'

# These specs previously drove Tilt.new(template_string), which treats its
# argument as a *filename*. It raised "No template engine registered for
# {{system "ls"}}" before FlavourSaver was ever invoked, so both examples
# passed without executing a single line of the runtime. Drive
# FlavourSaver.evaluate directly so the dispatch path is actually exercised.
describe "Template-driven method dispatch" do
  # A plain object, to show the context needs nothing special to be exploitable.
  let(:context) { Object.new }

  def evaluate(template, ctx = context)
    FlavourSaver.evaluate(template, ctx)
  end

  describe "refuses methods inherited from Object" do
    {
      'instance_eval'      => '{{instance_eval "$fs_rce_canary = :pwned"}}',
      'instance_exec'      => '{{instance_exec "$fs_rce_canary = :pwned"}}',
      'send'               => '{{send "instance_eval" "$fs_rce_canary = :pwned"}}',
      '__send__'           => '{{__send__ "instance_eval" "$fs_rce_canary = :pwned"}}',
      'public_send'        => '{{public_send "instance_eval" "$fs_rce_canary = :pwned"}}',
      'method'             => '{{method "instance_eval"}}',
      'object path form'   => '{{this.instance_eval "$fs_rce_canary = :pwned"}}',
      'subexpression form' => '{{log (instance_eval "$fs_rce_canary = :pwned")}}',
      # Decorator#method_missing is public and forwards to the context, and
      # method_missing is private on BasicObject so it never appeared in
      # Object.instance_methods.
      'method_missing'     => '{{method_missing "instance_eval" "$fs_rce_canary = :pwned"}}',
    }.each do |description, template|
      it "refuses #{description}" do
        $fs_rce_canary = nil

        expect { evaluate(template) }.to raise_error(FlavourSaver::ForbiddenMethodException)

        # Assert on the side effect too, not just the exception type: a payload
        # that executes *and then* raises would satisfy raise_error alone.
        expect($fs_rce_canary).to be_nil
      end
    end

    it 'refuses block expression form' do
      $fs_rce_canary = nil

      expect {
        evaluate('{{#instance_eval "$fs_rce_canary = :pwned"}}x{{/instance_eval}}')
      }.to raise_error(FlavourSaver::ForbiddenMethodException)

      expect($fs_rce_canary).to be_nil
    end

    it 'does not shell out via send' do
      expect { evaluate(%q({{send "system" "echo pwned"}})) }
        .to raise_error(FlavourSaver::ForbiddenMethodException)
    end

    it 'refuses regardless of the context object' do
      [Object.new, { 'a' => 'b' }, Struct.new(:name).new('x'), 'a string', []].each do |ctx|
        $fs_rce_canary = nil

        expect { evaluate('{{instance_eval "$fs_rce_canary = :pwned"}}', ctx) }
          .to raise_error(FlavourSaver::ForbiddenMethodException)

        expect($fs_rce_canary).to be_nil
      end
    end

    # Integer, Symbol and Float have no singleton class, so the visibility check
    # raises TypeError rather than NameError. It must still resolve to a refusal
    # (a primitive cannot carry a singleton method) rather than leaking an
    # unrescued TypeError past the UnknownHelperException contract.
    it 'refuses on primitive contexts without leaking TypeError' do
      [5, :sym, 1.5].each do |ctx|
        $fs_rce_canary = nil

        expect { evaluate('{{instance_eval "$fs_rce_canary = :pwned"}}', ctx) }
          .to raise_error(FlavourSaver::ForbiddenMethodException)

        expect($fs_rce_canary).to be_nil
      end
    end

    # The private forbidden_method? predicate must be correct on its own, not
    # only behind the decorator wrapping in evaluate_call, since a primitive
    # reaching it undecorated is the exact case that raised TypeError.
    it 'the predicate refuses inherited methods on an undecorated primitive' do
      runtime = FlavourSaver::Runtime.new(FlavourSaver.parse(FlavourSaver.lex('')), context)
      expect(runtime.send(:forbidden_method?, 5, 'instance_eval')).to be true
      # ...but leaves a primitive's own domain method dispatchable.
      expect(runtime.send(:forbidden_method?, 5, 'bit_length')).to be false
    end

    it 'is catchable as UnknownHelperException, for existing rescue clauses' do
      expect { evaluate('{{instance_eval "1"}}') }
        .to raise_error(FlavourSaver::UnknownHelperException)
    end

    # Helpers.decorate_with only mixes in the helpers named in the runtime's
    # helper list when that list is non-empty. A guard that consulted the global
    # registry would exempt a name that was never mixed in, and dispatch would
    # reach Object's implementation of it.
    it 'refuses a registered helper name that was scoped out of this runtime' do
      $fs_rce_canary = nil
      FlavourSaver::Helpers.register_helper(:send) { 'helper!' }

      ast = FlavourSaver.parse(FlavourSaver.lex('{{send "instance_eval" "$fs_rce_canary = :pwned"}}'))

      expect { FlavourSaver::Runtime.new(ast, context, {}, [:this]).to_s }
        .to raise_error(FlavourSaver::ForbiddenMethodException)

      expect($fs_rce_canary).to be_nil
    ensure
      FlavourSaver::Helpers.deregister_helper(:send)
    end

    # Private Kernel methods are not refused by name -- doing so would break the
    # ~60 context methods that share a name with one (format, open, select...).
    # They are unreachable instead: public_send cannot call them, so they fall
    # through to Decorator#method_missing, which also uses public_send. These
    # assert non-execution rather than an exception type, because which error
    # surfaces depends on the context object.
    describe "private Kernel methods are unreachable" do
      def expect_no_execution(template, ctx)
        canary = File.join(Dir.tmpdir, "fs_rce_#{Process.pid}_#{rand(1 << 32)}")
        begin
          evaluate(format(template, canary), ctx)
        rescue StandardError
          # An exception is an acceptable outcome; execution is not.
        end
        expect(File.exist?(canary)).to be false
      ensure
        FileUtils.rm_f(canary)
      end

      %w[system eval exec fork spawn require load syscall].each do |name|
        it "does not execute #{name}" do
          expect_no_execution(%({{#{name} "touch %s"}}), context)
        end
      end

      # The OSVDB-110796 payload: a proxy or delegator answering true to
      # everything used to make every private Kernel method reachable.
      it 'does not execute against a context with a permissive respond_to?' do
        permissive = Class.new { def respond_to?(name, priv = false); true; end }.new
        expect_no_execution('{{system "touch %s"}}', permissive)
      end

      it 'does not execute via the send trampoline' do
        expect_no_execution('{{send "system" "touch %s"}}', context)
      end
    end

    # Object#try forwards to public_send, so a guard keyed on the method's owner
    # being Object/Kernel/BasicObject would miss it: ActiveSupport mixes try into
    # Object via its own module.
    it 'refuses methods mixed into Object by a framework' do
      $fs_rce_canary = nil

      expect { evaluate('{{try "instance_eval" "$fs_rce_canary = :pwned"}}') }
        .to raise_error(FlavourSaver::ForbiddenMethodException)

      expect($fs_rce_canary).to be_nil
    end
  end

  # Named coverage of the dangerous surface. These are behavioural rather than
  # assertions about an internal list, so they keep their meaning regardless of
  # how the guard is implemented.
  describe "refuses each dangerous name individually" do
    # No predicate names here: the lexer's IDENT rule is /([A-Za-z_]\w*)/, so a
    # trailing ? cannot form part of a template identifier.
    %w[instance_eval instance_exec send __send__ public_send method
       define_singleton_method singleton_class class extend freeze
       method_missing tap then itself].each do |name|
      it "refuses #{name}" do
        expect { evaluate("{{#{name}}}") }
          .to raise_error(FlavourSaver::ForbiddenMethodException)
      end
    end
  end

  # Templates loaded from disk go through Tilt and FlavourSaver::Template rather
  # than FlavourSaver.evaluate, so the refusal is asserted on that path too. This
  # is what the original specs were reaching for: they passed the template *source*
  # to Tilt.new, which expects a filename, so no engine matched and the whole
  # suite short-circuited. Point it at a real .hbs fixture, as the other
  # fixture specs do.
  describe "refuses payloads in templates loaded from disk" do
    let(:fixture) { File.expand_path('../../fixtures/rce.hbs', __FILE__) }

    it 'refuses when rendered through Tilt' do
      $fs_rce_canary = nil

      expect { Tilt.new(fixture).render(context) }
        .to raise_error(FlavourSaver::ForbiddenMethodException)

      expect($fs_rce_canary).to be_nil
    end

    it 'has a fixture that really does contain a payload' do
      expect(File.read(fixture)).to include 'instance_eval'
    end
  end

  # The fix must not be so broad that it breaks ordinary templates.
  describe "still allows legitimate dispatch" do
    it 'calls a method the context actually defines' do
      klass = Class.new { def greeting; 'hello'; end }
      expect(evaluate('{{greeting}}', klass.new)).to eq 'hello'
    end

    it 'reads a data field named after an Object method via segment literals' do
      expect(evaluate('{{[class]}}', { 'class' => 'btn-primary' })).to eq 'btn-primary'
      expect(evaluate('{{[hash]}}',  { 'hash'  => 'abc123' })).to eq 'abc123'
    end

    it 'allows a deliberately registered helper to shadow an Object method' do
      FlavourSaver::Helpers.register_helper(:hash) { 'abc123' }
      expect(evaluate('{{hash}}')).to eq 'abc123'
    ensure
      FlavourSaver::Helpers.deregister_helper(:hash)
    end

    it 'allows a local to shadow an Object method' do
      runtime = FlavourSaver::Runtime.new(
        FlavourSaver.parse(FlavourSaver.lex('{{hash}}')),
        context,
        { 'hash' => proc { 'abc123' } }
      )
      expect(runtime.to_s).to eq 'abc123'
    end

    it 'still renders nothing for an unknown, non-forbidden method' do
      expect(evaluate('{{no_such_method}}')).to eq ''
    end

    # Roughly sixty lexable names collide with a private Kernel method. They are
    # plausible domain names and dispatched fine before 4.0.1, so refusing them
    # would be a breaking change smuggled into a security patch.
    %w[format open select print test load p raise loop gets rand warn catch].each do |name|
      it "dispatches a context method named #{name}" do
        klass = Class.new { define_method(name) { "value-#{name}" } }
        expect(evaluate("{{#{name}}}", klass.new)).to eq "value-#{name}"
      end
    end
  end
end
