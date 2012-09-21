module FlavourSaver
  class RailsPartial 
    def self.register_partial(*args)
      raise RuntimeError, "No need to register partials inside Rails."
    end
    def self.reset_partials; end
    def self.partials; end
    def self.fetch; end
  end
end
