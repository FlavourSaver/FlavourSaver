require "flavour_saver/version"
require 'tilt'

module FlavourSaver

  autoload :Lexer,          'flavour_saver/lexer'
  autoload :Parser,         'flavour_saver/parser'
  autoload :Runtime,        'flavour_saver/runtime'
  autoload :Helpers,        'flavour_saver/helpers'
  autoload :Partial,        'flavour_saver/partial'
  autoload :RailsPartial,   'flavour_saver/rails_partial'
  autoload :Template,       'flavour_saver/template'
  autoload :NodeCollection, 'flavour_saver/node_collection'

  if defined? Rails
    class Engine < Rails::Engine
    end

    ActiveSupport.on_load(:action_view) do
      handler = proc do |template|
        # I'd rather be caching the Runtime object ready to fire, but apparently I don't get that luxury.
        <<-SOURCE
        FlavourSaver.evaluate((begin;#{template.source.inspect};end),self)
        SOURCE
      end
      ActionView::Template.register_template_handler(:hbs, handler)
      ActionView::Template.register_template_handler(:handlebars, handler)
    end

    @default_logger = proc { Rails.logger }
    @partial_handler = RailsPartial
  else
    @default_logger = proc { Logger.new }
    @partial_handler = Partial
  end

  module_function

  def lex(template)
    Lexer.lex(template)
  end

  def parse(tokens)
    Parser.parse(tokens)
  end

  def evaluate(template,context)
    Runtime.run(parse(lex(template)), context)
  end

  def register_helper(*args,&b)
    Helpers.register_helper(*args,&b)
  end

  def reset_helpers
    Helpers.reset_helpers
  end

  def register_partial(name,content=nil,&block)
    Partial.register_partial(name,content,&block)
  end

  def reset_partials
    Partial.reset_partials
  end

  def logger
    @logger || @default_logger.call
  end

  def logger=(logger)
    @logger=logger
  end

  Tilt.register(Template, 'handlebars', 'hbs')
end

FS = FlavourSaver
